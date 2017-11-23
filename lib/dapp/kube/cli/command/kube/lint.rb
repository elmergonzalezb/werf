module Dapp::Kube::CLI::Command
  class Kube < ::Dapp::CLI
    class Lint < Base
      banner <<BANNER.freeze
Usage:

  dapp kube lint [options] [REPO]

Options:
BANNER

      option :namespace,
        long: '--namespace NAME',
        default: nil

      option :image_version,
        long: '--image-version IMAGE_VERSION',
        default: 'latest'

      option :helm_set_options,
        long: '--set STRING_ARRAY',
        default: [],
        proc: proc { |v| composite_options(:helm_set) << v }

      option :helm_values_options,
        long: '--values FILE_PATH',
        default: [],
        proc: proc { |v| composite_options(:helm_values) << v }

      option :helm_secret_values_options,
        long: '--secret-values FILE_PATH',
        default: [],
        proc: proc { |v| composite_options(:helm_secret_values) << v }

      def run(argv = ARGV)
        self.class.parse_options(self, argv)

        run_dapp_command(nil, options: cli_options, log_running_time: false) do |dapp|
          repo = if not cli_arguments[0].nil?
            self.class.required_argument(self, 'repo')
          else
            dapp.name
          end

          dapp.options[:repo] = repo

          dapp.public_send(run_method)
        end
      end

    end
  end
end