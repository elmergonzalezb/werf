---
title: Интеграция с GitLab CI/CD
sidebar: documentation
permalink: documentation/guides/gitlab_ci_cd_integration.html
author: Artem Kladov <artem.kladov@flant.com>
---

## Обзор задачи

В статье рассматривается пример настройки CI/CD с использованием GitLab CI и werf.

## Требования

* Кластер Kubernetes и настроенный для работы с ним `kubectl`.
* GitLab-сервер версии выше 10.x либо учетная запись на [gitlab.com](https://gitlab.com/).
* Docker registry, встроенный в GitLab или выделенный.
* Приложение, которое успешно собирается и деплоится с werf.

## Инфраструктура

![scheme]({% asset howto_gitlabci_scheme.png @path %})

* Кластер Kubernetes.
* GitLab со встроенным Docker registry.
* Узел, на котором установлен werf (узел сборки и деплоя).

Организовать работу werf внутри Docker-контейнера можно, но мы не поддерживаем данный способ.
Найти информацию по этому вопросу и обсудить можно в [issue](https://github.com/flant/werf/issues/1926).
В данном примере и в целом мы рекомендуем использовать _shell executor_.

Для хранения кэша сборки и служебных файлов werf использует папку `~/.werf`. Папка должна сохраняться и быть доступной на всех этапах pipeline. 
Это ещё одна из причин по которой мы рекомендуем отдавать предпочтение _shell executor_ вместо эфемерных окружений.

Процесс деплоя требует наличия доступа к кластеру через `kubectl`, поэтому необходимо установить и настроить `kubectl` на узле, с которого будет запускаться werf.
Если не указывать конкретный контекст опцией `--kube-context` или переменной окружения `$WERF_KUBE_CONTEXT`, то werf будет использовать контекст `kubectl` по умолчанию.  

В конечном счете werf требует наличия доступа:
- к Git-репозиторию кода приложения;
- к Docker registry;
- к кластеру Kubernetes.

### Настройка runner

На узле, где предполагается запуск werf, установим и настроим GitLab-runner:
1. Создадим проект в GitLab и добавим push кода приложения.
1. Получим токен регистрации GitLab-runner'а:
   * заходим в проекте в GitLab `Settings` —> `CI/CD`;
   * во вкладке `Runners` необходимый токен находится в секции `Setup a specific Runner manually`.
1. Установим GitLab-runner [по инструкции](https://docs.gitlab.com/runner/install/linux-manually.html).
1. Зарегистрируем `gitlab-runner`, выполнив [шаги](https://docs.gitlab.com/runner/register/index.html) за исключением следующих моментов:
   * используем `werf` в качестве тега runner'а;
   * используем `shell` в качестве executor для runner'а.
1. Добавим пользователя `gitlab-runner` в группу `docker`.

   ```shell
   sudo usermod -aG docker gitlab-runner
   ```

1. Установим [Docker](https://kubernetes.io/docs/setup/independent/install-kubeadm/#installing-docker) и настроим `kubectl`, если они не были установлены ранее.
1. Установим [зависимости werf]({{ site.baseurl }}/documentation/guides/getting_started.html#требования).
1. Установим [multiwerf](https://github.com/flant/multiwerf) пользователем `gitlab-runner`:

   ```shell
   sudo su gitlab-runner
   mkdir -p ~/bin
   cd ~/bin
   curl -L https://raw.githubusercontent.com/flant/multiwerf/master/get.sh | bash
   ```

1. Скопируем файл конфигурации `kubectl` в домашнюю папку пользователя `gitlab-runner`.
   ```shell
   mkdir -p /home/gitlab-runner/.kube &&
   sudo cp -i /etc/kubernetes/admin.conf /home/gitlab-runner/.kube/config &&
   sudo chown -R gitlab-runner:gitlab-runner /home/gitlab-runner/.kube
   ```

После того, как GitLab-runner настроен, можно переходить к настройке pipeline.

## Pipeline

Создадим файл `.gitlab-ci.yml` в корне проекта и добавим следующие строки:

```yaml
stages:
  - build-and-publish
  - deploy
  - dismiss
  - cleanup
```

Мы определили следующие стадии:
* `build-and-publish` — стадия сборки и публикации образов приложения;
* `deploy` — стадия деплоя приложения для одного из контуров кластера;
* `dismiss` — стадия удаления приложения для динамических контуров кластера;
* `cleanup` — стадия очистки хранилища стадий и Docker registry.

### Сборка и публикация образов приложения

Добавим следующие строки в файл `.gitlab-ci.yml`:

```yaml
Build and Publish:
  stage: build-and-publish
  script:
    - type multiwerf && . $(multiwerf use 1.1 stable --as-file)
    - type werf && source $(werf ci-env gitlab --verbose --as-file)
    - werf build-and-publish
  except:
    - schedules
  tags:
    - werf
```

Забегая вперед, очистка хранилища стадий и Docker registry предполагает запуск соответствующего задания по расписанию.
Так как при очистке не требуется выполнять сборку образов, то указываем `except: schedules`, чтобы стадия сборки не запускалась в случае работы pipeline по расписанию.

Для авторизации в Docker registry (при выполнении push/pull образов) werf использует переменную окружения GitLab `CI_JOB_TOKEN` (подробнее про модель разграничения доступа при выполнении заданий в GitLab можно прочитать [здесь](https://docs.gitlab.com/ee/user/project/new_ci_build_permissions_model.html)).
Это не единственный, но самый рекомендуемый вариант в случае работы с GitLab (подробно про авторизацию werf в Docker registry можно прочесть [здесь]({{ site.baseurl }}/documentation/reference/working_with_docker_registries.html#авторизация-docker)).
В простейшем случае, если вы используете встроенный в GitLab Docker registry, вам не нужно делать никаких дополнительных действий для авторизации.

Если вам нужно чтобы werf не использовал переменную `CI_JOB_TOKEN` либо вы используете невстроенный в GitLab Docker registry (например, `Google Container Registry`), то можно ознакомиться с вариантами авторизации [здесь]({{ site.baseurl }}/documentation/reference/working_with_docker_registries.html#авторизация-docker).

> Для удаления образов из встроенного в GitLab Docker registry требуется `Personal Access Token`. Подробнее в разделе посвященном [очистке](#очистка-образов)

### Выкат приложения

Набор контуров (а равно — окружений GitLab) в кластере Kubernetes для деплоя приложения зависит от ваших потребностей, но наиболее используемые контуры следующие:
* Контур production. Финальный контур в pipeline, предназначенный для эксплуатации версии приложения, доставки конечному пользователю.
* Контур staging. Контур, который может использоваться для проведения финального тестирования приложения в приближенной к production среде. 
* Контур review. Динамический (временный) контур, используемый разработчиками при разработке для оценки работоспособности написанного кода, первичной оценки работоспособности приложения и т.п.

> Описанный набор и их функции — это не правила и вы можете описывать CI/CD процессы под свои нужны с произвольным количеством контуров. 
Далее будут представлены популярные стратегии и практики, на базе которых мы предлагаем выстраивать ваши процессы в GitLab CI 

Прежде всего необходимо описать шаблон, который мы будем использовать во всех заданиях деплоя, что позволит уменьшить размер файла `.gitlab-ci.yml` и улучшит его читаемость.

Добавим следующие строки в файл `.gitlab-ci.yml`:

```yaml
.base_deploy: &base_deploy
  stage: deploy
  script:
    - type multiwerf && . $(multiwerf use 1.1 stable --as-file)
    - type werf && source $(werf ci-env gitlab --verbose --as-file)
    ## Следующая команда непосредственно выполняет деплой
    - werf deploy --set "global.ci_url=$(echo ${CI_ENVIRONMENT_URL} | cut -d / -f 3)"
  ## Обратите внимание, что стадия деплоя обязательно зависит от стадии сборки. В случае ошибки на стадии сборки деплой не будет выполняться.
  dependencies:
    - Build and Publish
  except:
    - schedules
  tags:
    - werf
```

Обратите внимание на команду `werf deploy`.
Эта команда — основной шаг в процессе деплоя. В параметре `global.ci_url` передается URL для доступа к разворачиваемому в контуре приложению.
Вы можете использовать эти данные в ваших helm-шаблонах, например, для конфигурации Ingress-ресурсов.

Для того чтобы деплоить приложение в разные контуры кластера в helm-шаблонах можно использовать переменную `.Values.global.env`, обращаясь к ней внутри Go-шаблона (Go template).
Во время деплоя werf устанавливает переменную `global.env` в соответствии с именем окружения GitLab.

Таким образом, при использовании шаблона `base_deploy` необходимо определить окружение GitLab в месте его использования:

```yaml
environment:
  name: <environment name>
  url: <url>
```

> Для review окружения так же потребуются дополнительные атрибуты, но они будут рассмотрены отдельно в соответствующей секции

Конфигурации для различных окружений отличаются секцией `environment`, а также условиями и правилами, по которым происходит выкат.

#### Варианты организации review окружения

В данном задании werf удаляет helm-релиз, и, соответственно, namespace в Kubernetes со всем его содержимым ([werf dismiss]({{ site.baseurl }}/documentation/cli/main/dismiss.html)). Это задание может быть запущено вручную после деплоя на review-контур, а также оно может быть запущено GitLab-сервером, например, при удалении соответствующей ветки в результате слияния ветки с master и указания соответствующей опции в интерфейсе GitLab.

##### №1 Полуавтоматический режим, лейблы Вкл./Выкл. (рекомендованный)

##### №2 Автоматически по имени ветки

```yaml
Review:
  <<: *base_deploy
  environment:
    name: review/${CI_COMMIT_REF_SLUG}
    ## Измените суффикс доменного имени (здесь — `kube.DOMAIN`) при необходимости
    url: http://${CI_PROJECT_NAME}-${CI_COMMIT_REF_SLUG}.kube.DOMAIN
  only:
    - /^.*review.*$/
  except:
    - master
    - schedules
```

##### №3 Ручной

```yaml
Review App:
  <<: *base_deploy
  environment:
    name: review/${CI_COMMIT_REF_SLUG}
    ## Измените суффикс доменного имени (здесь — `kube.DOMAIN`) при необходимости
    url: http://${CI_PROJECT_NAME}-${CI_COMMIT_REF_SLUG}.kube.DOMAIN
    on_stop: Stop Review App
  only:
    - branches
  except:
    - master
    - schedules
  when: manual

Stop Review App:
  stage: dismiss
  script:
    - type multiwerf && . $(multiwerf use 1.1 stable --as-file)
    - type werf && source $(werf ci-env gitlab --verbose --as-file)
    - werf dismiss --with-namespace
  environment:
    name: review/${CI_COMMIT_REF_SLUG}
  tags:
    - werf
  dependencies:
    - Review App
  only:
    - branches
  except:
    - master
    - schedules
  when: manual
```

#### Варианты организации production и staging окружений 

##### №1 Fast and Furious или True CI/CD (рекомендованный)

Выкат в **production** происходит автоматически при любых изменениях в master. Выполнить выкат в **staging** можно по кнопке в MR.

```yaml
Deploy to Staging:
  <<: *base_deploy
  environment:
    name: stage
    url: http://${CI_PROJECT_NAME}-${CI_COMMIT_REF_SLUG}.kube.DOMAIN
  only:
    - merge_requests 
  when: manual

Deploy to Production:
  <<: *base_deploy
  environment:
    name: production
    url: http://www.company.my
  only:
    - master
```

Варианты отката изменений в production:
- [revert изменений](https://git-scm.com/docs/git-revert) в master (**рекомендованный**);
- выкат стабильного MR или воспользовавшись кнопкой [Rollback](https://docs.gitlab.com/ee/ci/environments.html#what-to-expect-with-a-rollback).

##### №2 Push the Button

Выкат **production** осуществляется по кнопке у комита в master, а выкат в **staging** происходит автоматически при любых изменениях в master.

```yaml
Deploy to Staging:
  <<: *base_deploy
  environment:
    name: stage
    url: http://${CI_PROJECT_NAME}-${CI_COMMIT_REF_SLUG}.kube.DOMAIN
  only:
    - master

Deploy to Production:
  <<: *base_deploy
  environment:
    name: production
    url: http://www.company.my
  only:
    - master
  when: manual  
```

Варианты отката изменений в production:
- по кнопке у стабильного комита или воспользовавшись кнопкой [Rollback](https://docs.gitlab.com/ee/ci/environments.html#what-to-expect-with-a-rollback) (**рекомендованный**);
- выкат стабильного MR и нажатии кнопки.

##### №3 Tag everything (рекомендованный)

Выкат в **production** выполняется при проставлении тега, а в **staging** по кнопке у комита в master.

```yaml
Deploy to Staging:
  <<: *base_deploy
  environment:
    name: stage
    url: http://${CI_PROJECT_NAME}-${CI_COMMIT_REF_SLUG}.kube.DOMAIN
  only:
    - master
  when: manual

Deploy to Production:
  <<: *base_deploy
  environment:
    name: production
    url: http://www.company.my
  only:
    - tags
```

Варианты отката изменений в production:
- нажатие кнопки на другом теге (**рекомендованный**);
- создание нового тега на старый комит (так делать не надо).

##### №4 Branch, branch, branch!

Выкат в **production** происходит автоматически при любых изменениях в ветке production, а в **staging** при любых изменениях в ветке master.

```yaml
Deploy to Staging:
  <<: *base_deploy
  environment:
    name: stage
    url: http://${CI_PROJECT_NAME}-${CI_COMMIT_REF_SLUG}.kube.DOMAIN
  only:
    - master

Deploy to Production:
  <<: *base_deploy
  environment:
    name: production
    url: http://www.company.my
  only:
    - production
```

Варианты отката изменений в production:
- воспользовавшись кнопкой [Rollback](https://docs.gitlab.com/ee/ci/environments.html#what-to-expect-with-a-rollback);
- [revert изменений](https://git-scm.com/docs/git-revert) в ветке production;
- [revert изменений](https://git-scm.com/docs/git-revert) в master и fast-forward merge в ветку production;
- удаление коммита из ветки production и push-force.

### Очистка образов

В werf встроен эффективный механизм очистки, который позволяет избежать переполнения Docker registry и диска сборочного узла от устаревших и неиспользуемых образов.
Более подробно ознакомиться с функционалом очистки, встроенным в werf, можно [здесь]({{ site.baseurl }}/documentation/reference/cleaning_process.html).

В результате работы werf наполняет локальное хранилище стадий, а также Docker registry собранными образами.

Для работы очистки в файле `.gitlab-ci.yml` выделена отдельная стадия — `cleanup`.

Чтобы использовать очистку, необходимо создать `Personal Access Token` в GitLab с необходимыми правами. С помощью данного токена будет осуществляться авторизация в Docker registry перед очисткой.

Для вашего тестового проекта вы можете просто создать `Personal Access Token` а вашей учетной записи GitLab. Для этого откройте страницу `Settings` в GitLab (настройки вашего профиля), затем откройте раздел `Access Token`. Укажите имя токена, в разделе Scope отметьте `api` и нажмите `Create personal access token` — вы получите `Personal Access Token`.

Чтобы передать `Personal Access Token` в переменную окружения GitLab откройте ваш проект, затем откройте `Settings` —> `CI/CD` и разверните `Variables`. Создайте новую переменную окружения `WERF_IMAGES_CLEANUP_PASSWORD` и в качестве ее значения укажите содержимое `Personal Access Token`. Для безопасности отметьте созданную переменную как `protected`.

Добавим следующие строки в файл `.gitlab-ci.yml`:

```yaml
Cleanup:
  stage: cleanup
  script:
    - type multiwerf && . $(multiwerf use 1.1 stable --as-file)
    - type werf && source $(werf ci-env gitlab --tagging-strategy tag-or-branch --verbose --as-file)
    - docker login -u nobody -p ${WERF_IMAGES_CLEANUP_PASSWORD} ${WERF_IMAGES_REPO}
    - werf cleanup
  only:
    - schedules
  tags:
    - werf
```

Стадия очистки запускается только по расписанию, которое вы можете определить открыв раздел `CI/CD` —> `Schedules` настроек проекта в GitLab. Нажмите кнопку `New schedule`, заполните описание задания и определите шаблон запуска в обычном cron-формате. В качестве ветки оставьте master (название ветки не влияет на процесс очистки), отметьте `Active` и сохраните pipeline.

> Как это работает:
   - `werf ci-env` создает временный конфигурационный файл для docker (отдельный при каждом запуске и соответственно для каждого задания GitLab), а также экспортирует переменную окружения DOCKER_CONFIG со значением пути к созданному конфигурационному файлу;
   - `docker login` использует временный конфигурационный файл для docker, путь к которому был указан ранее в переменной окружения DOCKER_CONFIG для авторизации в Docker registry;
   - `werf cleanup` также использует временный конфигурационный файл из DOCKER_CONFIG.

## .gitlab-ci.yml

// TODO 
