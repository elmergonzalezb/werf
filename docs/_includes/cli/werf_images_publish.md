{% if include.header %}
{% assign header = include.header %}
{% else %}
{% assign header = "###" %}
{% endif %}
Build final images using each specified tag with the tagging strategy and push into images repo.

New docker layer with service info about tagging strategy will be built for each tag of each image  
from werf.yaml. Images will be pushed into docker repo with the names IMAGES_REPO/IMAGE_NAME:TAG.   
See more info about publish process: [https://werf.io/documentation/reference/publish_process.html](https://werf.io/documentation/reference/publish_process.html).

If one or more IMAGE_NAME parameters specified, werf will publish only these images from werf.yaml.

{{ header }} Syntax

```shell
werf images publish [IMAGE_NAME...] [options]
```

{{ header }} Examples

```shell
  # Publish images into myregistry.mydomain.com/myproject images repo using 'mybranch' tag and git-branch tagging strategy
  $ werf images publish --stages-storage :local --images-repo myregistry.mydomain.com/myproject --tag-git-branch mybranch
```

{{ header }} Options

```shell
      --dir='':
            Change to the specified directory to find werf.yaml config
      --docker-config='':
            Specify docker config directory path. Default $WERF_DOCKER_CONFIG or $DOCKER_CONFIG or  
            ~/.docker (in the order of priority)
            Command needs granted permissions to read and pull images from the specified stages     
            storage and push images into images repo
  -h, --help=false:
            help for publish
      --home-dir='':
            Use specified dir to store werf cache files and dirs (default $WERF_HOME or ~/.werf)
  -i, --images-repo='':
            Docker Repo to store images (default $WERF_IMAGES_REPO)
      --images-repo-docker-hub-password='':
            Docker Hub password for images repo (default $WERF_IMAGES_REPO_DOCKER_HUB_PASSWORD,     
            $WERF_REPO_DOCKER_HUB_PASSWORD)
      --images-repo-docker-hub-token='':
            Docker Hub token for images repo (default $WERF_IMAGES_REPO_DOCKER_HUB_TOKEN,           
            $WERF_REPO_DOCKER_HUB_TOKEN)
      --images-repo-docker-hub-username='':
            Docker Hub username for images repo (default $WERF_IMAGES_REPO_DOCKER_HUB_USERNAME,     
            $WERF_REPO_DOCKER_HUB_USERNAME)
      --images-repo-github-token='':
            GitHub token for images repo (default $WERF_IMAGES_REPO_GITHUB_TOKEN,                   
            $WERF_REPO_GITHUB_TOKEN)
      --images-repo-implementation='':
            Choose repo implementation for images repo.
            The following docker registry implementations are supported: ecr, acr, default,         
            dockerhub, gcr, github, gitlab, harbor, quay.
            Default $WERF_IMAGES_REPO_IMPLEMENTATION, $WERF_REPO_IMPLEMENTATION or auto mode        
            (detect implementation by a registry).
      --images-repo-mode='auto':
            Define how to store in images repo: multirepo or monorepo.
            Default $WERF_IMAGES_REPO_MODE or auto mode
      --insecure-registry=false:
            Use plain HTTP requests when accessing a registry (default $WERF_INSECURE_REGISTRY)
      --kube-config='':
            Kubernetes config file path
      --kube-context='':
            Kubernetes config context (default $WERF_KUBE_CONTEXT)
      --log-color-mode='auto':
            Set log color mode.
            Supported on, off and auto (based on the stdout’s file descriptor referring to a        
            terminal) modes.
            Default $WERF_LOG_COLOR_MODE or auto mode.
      --log-debug=false:
            Enable debug (default $WERF_LOG_DEBUG).
      --log-pretty=true:
            Enable emojis, auto line wrapping and log process border (default $WERF_LOG_PRETTY or   
            true).
      --log-project-dir=false:
            Print current project directory path (default $WERF_LOG_PROJECT_DIR)
      --log-quiet=false:
            Disable explanatory output (default $WERF_LOG_QUIET).
      --log-terminal-width=-1:
            Set log terminal width.
            Defaults to:
            * $WERF_LOG_TERMINAL_WIDTH
            * interactive terminal width or 140
      --log-verbose=false:
            Enable verbose output (default $WERF_LOG_VERBOSE).
      --repo-docker-hub-password='':
            Common Docker Hub password for any stages storage or images repo specified for the      
            command (default $WERF_REPO_DOCKER_HUB_PASSWORD)
      --repo-docker-hub-token='':
            Common Docker Hub token for any stages storage or images repo specified for the command 
            (default $WERF_REPO_DOCKER_HUB_TOKEN)
      --repo-docker-hub-username='':
            Common Docker Hub username for any stages storage or images repo specified for the      
            command (default $WERF_REPO_DOCKER_HUB_USERNAME)
      --repo-github-token='':
            Common GitHub token for any stages storage or images repo specified for the command     
            (default $WERF_REPO_GITHUB_TOKEN)
      --repo-implementation='':
            Choose common repo implementation for any stages storage or images repo specified for   
            the command.
            The following docker registry implementations are supported: ecr, acr, default,         
            dockerhub, gcr, github, gitlab, harbor, quay.
            Default $WERF_REPO_IMPLEMENTATION or auto mode (detect implementation by a registry).
      --skip-tls-verify-registry=false:
            Skip TLS certificate validation when accessing a registry (default                      
            $WERF_SKIP_TLS_VERIFY_REGISTRY)
      --ssh-key=[]:
            Use only specific ssh keys (Defaults to system ssh-agent or ~/.ssh/{id_rsa|id_dsa}, see 
            https://werf.io/documentation/reference/toolbox/ssh.html).
            Option can be specified multiple times to use multiple keys
  -s, --stages-storage='':
            Docker Repo to store stages or :local for non-distributed build (only :local is         
            supported for now; default $WERF_STAGES_STORAGE environment).
            More info about stages: https://werf.io/documentation/reference/stages_and_images.html
      --stages-storage-repo-docker-hub-password='':
            Docker Hub password for stages storage (default                                         
            $WERF_STAGES_STORAGE_REPO_DOCKER_HUB_PASSWORD, $WERF_REPO_DOCKER_HUB_PASSWORD)
      --stages-storage-repo-docker-hub-token='':
            Docker Hub token for stages storage (default                                            
            $WERF_STAGES_STORAGE_REPO_DOCKER_HUB_TOKEN, $WERF_REPO_DOCKER_HUB_TOKEN)
      --stages-storage-repo-docker-hub-username='':
            Docker Hub username for stages storage (default                                         
            $WERF_STAGES_STORAGE_REPO_DOCKER_HUB_USERNAME, $WERF_REPO_DOCKER_HUB_USERNAME)
      --stages-storage-repo-github-token='':
            GitHub token for stages storage (default $WERF_STAGES_STORAGE_REPO_GITHUB_TOKEN,        
            $WERF_REPO_GITHUB_TOKEN)
      --stages-storage-repo-implementation='':
            Choose repo implementation for stages storage.
            The following docker registry implementations are supported: ecr, acr, default,         
            dockerhub, gcr, github, gitlab, harbor, quay.
            Default $WERF_STAGES_STORAGE_REPO_IMPLEMENTATION, $WERF_REPO_IMPLEMENTATION or auto     
            mode (detect implementation by a registry).
  -S, --synchronization='':
            Address of synchronizer for multiple werf processes to work with a single stages        
            storage (default :local if --stages-storage=:local or kubernetes://werf-synchronization 
            if non-local stages-storage specified or $WERF_SYNCHRONIZATION if set). The same        
            address should be specified for all werf processes that work with a single stages       
            storage. :local address allows execution of werf processes from a single host only.
      --tag-by-stages-signature=false:
            Use stages-signature tagging strategy and tag each image by the corresponding signature 
            of last image stage (option can be enabled by specifying                                
            $WERF_TAG_BY_STAGES_SIGNATURE=true)
      --tag-custom=[]:
            Use custom tagging strategy and tag by the specified arbitrary tags.
            Option can be used multiple times to produce multiple images with the specified tags.
            Also can be specified in $WERF_TAG_CUSTOM* (e.g. $WERF_TAG_CUSTOM_TAG1=tag1,            
            $WERF_TAG_CUSTOM_TAG2=tag2)
      --tag-git-branch='':
            Use git-branch tagging strategy and tag by the specified git branch (option can be      
            enabled by specifying git branch in the $WERF_TAG_GIT_BRANCH)
      --tag-git-commit='':
            Use git-commit tagging strategy and tag by the specified git commit hash (option can be 
            enabled by specifying git commit hash in the $WERF_TAG_GIT_COMMIT)
      --tag-git-tag='':
            Use git-tag tagging strategy and tag by the specified git tag (option can be enabled by 
            specifying git tag in the $WERF_TAG_GIT_TAG)
      --tmp-dir='':
            Use specified dir to store tmp files and dirs (default $WERF_TMP_DIR or system tmp dir)
```

