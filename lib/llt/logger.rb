require "llt/logger/version"
require "colorize"

module LLT
  class Logger
    LEVELS = %w{ error info parser cf morph debug }
    # Numeric vals  0    1    2     3   4     5
    DEFAULT_LEVEL = 1

    @level = ENV["LLT_DEBUG"] ? normalized_level(ENV["LLT_DEBUG"]) : DEFAULT_LEVEL
    @loggers = []

    class << self
      attr_reader :loggers

      def level=(lev)
        return @level = nil if lev.nil?

        l = normalized_level(lev)
        unless valid_level?(l)
          l = @level || DEFAULT_LEVEL # DEFAULT_LEVEL catches invalid levels defined through the env var
          puts "LOG LEVEL ERROR".red + " #{lev} is unknown - falling back to #{l}"
        end

        @level = l
      end

      def level(n = nil)
        return nil if @level.nil?
        n ? n <= @level : @level
      end

      def new(*args)
        new_logger = super
        @loggers << new_logger
        new_logger
      end

      def clear
        @loggers.clear
      end

      def count(mapper = :count)
        @loggers.map(&mapper).inject(:+)
      end

      def errors
        messages.select { |message| message =~ /ERROR!/ }
      end

      def warnings
        messages.select { |message| message =~ /WARNING!/ }
      end

      def messages_that_match(regexp)
        messages.select { |message| message =~ regexp }
      end

      def count_errors
        count(:errors)
      end

      def count_warnings
        count(:warnings)
      end

      def normalized_level(lev)
        if lev.is_a? Fixnum
          lev
        else
          LEVELS.index(lev.to_s) || -1 # -1 to fail the valid_level? test
        end
      end

      private

      def messages
        @loggers.flat_map(&:logs)
      end

      def valid_level?(lev)
        lev.between?(0, 5)
      end
    end

    attr_reader :title, :logs, :errors, :warnings

    def initialize(title = "", indent = "", default: :info)
      @title  = title
      @indent = to_whitespace(indent)
      @default = default
      @logs   = []
      @errors   = 0
      @warnings = 0
    end

    def log(*args)
      send(@default, *args)
      # TODO Exception Handling
    end

    def error(message, indent = "")
      message = "ERROR! #{message}".light_red
      if level(0)
        log_message(message, indent)
        @errors += 1
      end
    end

    def warning(message, indent = "")
      message = "WARNING! #{message}".yellow
      if level(1)
        log_message(message, indent)
        @warnings += 1
      end
    end

    def info(message, indent = "")
      log_message(message, indent) if level(1)
    end

    def parser(message, indent = "")
      log_message(message, indent) if level(2)
    end

    def cf(message, indent = "")
      log_message(message, indent) if level(3)
    end

    def morph(message, indent = "")
      log_message(message, indent) if level(4)
    end

    def debug(message, indent = "")
      log_message(message, indent) if level(5)
    end

    def bare(message, indent = 0)
      lev = Logger.normalized_level(@default)
      puts "#{to_whitespace(indent)}#{message}" if level(lev)
    end

    def count
      @logs.count
    end

    private

    def log_message(message, indent)
      t = (! @title.empty? ? "#{@title}: " : "")
      indentation = @indent + to_whitespace(indent)
      str = "#{indentation}#{t}#{message}"

      @logs << str
      puts str
    end

    def level(lev = nil)
      Logger.level(lev)
    end

    def to_whitespace(indent)
      if indent.is_a?(Fixnum)
        str = ""
        indent.times { str << " "}
        str
      else
        indent
      end
    end
  end
end
