require 'spec_helper'
require 'stringio'

describe LLT::Logger do
  before :all do
    string_io = StringIO.new
    @stdout = $stdout
    $stdout = string_io
  end

  it 'should have a version number' do
    LLT::Logger::VERSION.should_not be_nil
  end

  let(:logger) { LLT::Logger }
  describe ".level" do
    context "with no argument" do
      it "returns the current logger level" do
        logger.level.should_not be_nil
      end

      it "default level is info" do
        logger.level.should == 1
      end
    end

    context "with an argument" do
      it "returns true if inside of current logger level" do
        logger.level(1).should be_true
      end

      it "returns false if outside of current logger level" do
        logger.level = 2 # morph_debug
        logger.level(5).should be_false
      end
    end

    # don't know how to test that
    #it "can be set through env var LLT_DEBUG" do
    #  ENV["LLT_DEBUG"] = "info"
    #  logger.level.should == "info"
    #end
  end

  describe ".level=" do
    it "sets the logger level" do
      logger.level = "info"
      logger.level.should == 1 # info
    end

    it "needs to be set to a valid level, otherwise an error message is printed and the current level still in use" do
      old_level = logger.level

      $stdout.should receive(:puts)
      logger.level = "blabla"

      logger.level.should == old_level
    end

    it "can be set to nil - Logger will be shut down then" do
      logger.level = nil
      a = logger.new

      $stdout.should_not receive(:puts)
      a.error("")
      a.debug("")

      logger.level = :info # set back for other tests
    end
  end

  describe ".loggers" do
    it "returns an array of loggers" do
      logger.loggers.should be_an_instance_of Array
    end
  end

  describe ".new" do
    it "registers the newly created logger in Logger.loggers" do
      new_logger = logger.new
      logger.loggers.should include new_logger
    end

    it "and returns a new logger instance" do
      logger.new.should be_an_instance_of LLT::Logger
    end
  end

  describe ".clear" do
    it "clears all registered loggers" do
      5.times { logger.new }
      logger.loggers.should have_at_least(5).items
      logger.clear
      logger.loggers.should be_empty
    end
  end

  describe ".count" do
    it "counts all log messages" do
      logger.clear

      a = logger.new
      b = logger.new
      5.times { a.log("") }
      5.times { b.error("") }

      logger.count.should == 10
    end
  end

  describe ".count_errors" do
    it "counts all errors present" do
      logger.clear

      a = logger.new
      b = logger.new
      5.times { a.error("") }
      5.times { b.error("") }

      logger.count_errors.should == 10
    end
  end

  describe ".count_warnings" do
    it "counts all warnings present" do
      logger.clear

      a = logger.new
      b = logger.new
      5.times { a.warning("") }
      5.times { b.warning("") }

      logger.count_warnings.should == 10
    end
  end

  describe ".errors" do
    it "returns all logged error messages" do
      logger.clear

      a = logger.new
      b = logger.new
      5.times { a.error("") }
      3.times { b.warning("") }

      logger.errors.should have(5).items
    end
  end

  describe ".message_that_match" do
    it "returns all messages that match a given Regexp" do
      logger.clear

      a = logger.new
      b = logger.new
      5.times { a.log("arma") }
      3.times { b.log("multa") }

      logger.messages_that_match(/arma/).should have(5).items
    end
  end

  describe ".warnings" do
    it "returns all logged warnings" do
      logger.clear
      a = logger.new
      b = logger.new

      5.times { a.error("") }
      3.times { b.warning("") }

      logger.warnings.should have(3).items
    end
  end

  describe "#initialize" do
    it "takes title and indentation as arguments" do
      title = "a"
      nl = logger.new(title, "  ")
      nl.title.should == title
      nl.instance_variable_get("@indent").should == "  "
    end

    it "takes :default as keyword argument" do
      nl = logger.new(default: "parser")
      nl.instance_variable_get("@default").should == "parser"
    end

    it "default defaults to :info" do
      a = logger.new
      a.instance_variable_get("@default").should == :info
    end

    it "defaults '' and 0" do
      nl = logger.new
      nl.title.should == ""
      nl.instance_variable_get("@indent").should == ""
    end

    it "indentantion can be set with a Fixnum, converted to n whitespaces" do
      nl = logger.new("title", 3)
      nl.instance_variable_get("@indent").should == "   "
    end
  end

  describe "#log" do
    it "delegates to the set default" do
      a = logger.new(default: "cf")
      b = logger.new(default: "morph")

      a.should receive(:cf)
      b.should_not receive(:cf)

      a.log("") and b.log("")
    end

    it "all log calls take a message and an optional indent level that adds up to the default indentation" do
      a = logger.new("", 2)
      $stdout.should receive(:puts).with("    message")
      a.log("message", 2)
    end

    it "title is automatically added if present" do
      a = logger.new("Logger", 2)
      $stdout.should receive(:puts).with("  Logger: message")
      a.log("message")
    end
  end

  describe "#bare" do
    it "logs without title, without default intendation level and doesn't store the message" do
      a = logger.new("Title", 28)
      $stdout.should receive(:puts).with(" message")
      a.bare("message", 1)
      a.logs.should be_empty
    end

    it "default level matters and decides if anything happens at all" do
      logger.level = 3 # cf
      a = logger.new(default: :debug)
      b = logger.new(default: :info)

      $stdout.should receive(:puts).exactly(:once)

      a.bare("")
      b.bare("")
    end
  end

  describe "#logs" do
    it "logs are stored" do
      a = logger.new
      a.log("message")
      a.logs.should include "message"
    end
  end

  describe "#count" do
    it "counts number of logs" do
      a = logger.new
      5.times { a.log("") }
      a.count.should == 5
    end
  end

  describe "#errors" do
    it "counts the number of errors" do
      a = logger.new
      a.error("")
      a.errors.should == 1
    end
  end

  describe "#warnings" do
    it "counts the number of warnings" do
      a = logger.new
      a.warning("")
      a.warning("")
      a.warnings.should == 2
    end
  end

  after :all do
    $stdout = @stdout
  end
end
