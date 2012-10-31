require 'yaml'

module CodeRay
  module Encoders
    def self.theme_dir
      $:.select {|x| x =~ /coderay/}.first + " /coderay/styles/terminal"
    end

    # Outputs code highlighted for a color terminal.
    #
    # Note: This encoder is in beta. It currently doesn't use the Styles.
    #
    # Alias: +term+
    #
    # == Authors & License
    #
    # By Rob Aldred (http://robaldred.co.uk)
    #
    # Based on idea by Nathan Weizenbaum (http://nex-3.com)
    #
    # MIT License (http://www.opensource.org/licenses/mit-license.php)
    class Terminal < Encoder
      register_for :terminal

     protected

      def setup(options)
        super
        if !options[:theme]
          self.theme = "default"
        else
          self.theme = options[:theme]
        end
        @opened = []
        @subcolors = nil
      end

    public
      def initialize(args)
        super args
        @theme = nil
      end

      def theme=(name)
        @theme if @theme

        f = "#{Encoders.theme_dir}/#{name}.yaml"
        f = "#{Encoders.theme_dir}/default.yaml" if !File.exist? f
        @theme = ::YAML.load_file f
      end

      def theme
        @theme
      end

      def text_token text, kind
        if color = (@subcolors || @theme)[kind]
          if Hash === color
            if color[:self]
              color = color[:self]
            else
              @out << text
              return
            end
          end

          @out << ansi_colorize(color)
          @out << text.gsub("\n", ansi_clear + "\n" + ansi_colorize(color))
          @out << ansi_clear
          @out << ansi_colorize(@subcolors[:self]) if @subcolors && @subcolors[:self]
        else
          @out << text
        end
      end

      def begin_group kind
        @opened << kind
        @out << open_token(kind)
      end
      alias begin_line begin_group

      def end_group kind
        if @opened.empty?
          # nothing to close
        else
          @opened.pop
          @out << ansi_clear
          @out << open_token(@opened.last)
        end
      end

      def end_line kind
        if @opened.empty?
          # nothing to close
        else
          @opened.pop
          # whole lines to be highlighted,
          # eg. added/modified/deleted lines in a diff
          @out << "\t" * 100 + ansi_clear
          @out << open_token(@opened.last)
        end
      end

    private

      def open_token kind
        if color = @theme[kind]
          if Hash === color
            @subcolors = color
            ansi_colorize(color[:self]) if color[:self]
          else
            @subcolors = {}
            ansi_colorize(color)
          end
        else
          @subcolors = nil
          ''
        end
      end

      def ansi_colorize(color)
        Array(color).map { |c| "\e[#{c}m" }.join
      end
      def ansi_clear
        ansi_colorize(0)
      end
    end
  end
end
