require 'optparse'

#===============================================================================
# Command-line application argument parser and usage info
#===============================================================================

class CommandLine
  attr_reader :appname, :description, :examples, :positional
  attr_reader :help

  # Initialize the CommandLine. Options include:
  #
  #   :description   Multi-line description of the application.
  #   :examples      Multi-line application usage examples.
  #
  def initialize(options = {})
    @appname = File.basename($0)
    @description = []
    @examples = []
    @options = {}
    @parser = OptionParser.new do |opts|
      opts.summary_width = 10
      opts.banner = ''
      opts.on('-h', '--help', 'Display this help text.') do
        @help = true
      end
    end
    self.description = options[:description] if options[:description]
    self.examples    = options[:examples]    if options[:examples]
  end

  # Set the application description
  def description=(str)
    @description = str.strip.split("\n").map { |s| "    #{s.rstrip}\n" }
  end

  # Set the application usage examples
  def examples=(str)
    @examples = str.gsub('__APPNAME__', @appname).strip.split("\n").map { |s| "    #{s.rstrip}\n" }
  end

  # Add an option. Eg:
  #
  #     # Set the option, return the value to save
  #     args.option(:threshold, '-t', '--threshold VAL', 'A threshold value') do |v|
  #       Float(v)
  #     end
  #
  #     # For flags, no need to return the value 'true'
  #     args.option(:flag, '-f', '--flag', 'a flag')
  #
  #     # Grab the values after parsing
  #     args.threshold
  #     args.flag
  #
  def option(name, short, long, desc, default = nil, &block)
    # Save the option's default value and add the OptionParser logic
    @options[name] = default
    desc += " (default: #{default})" if default
    desc = desc.split("\n")
    @parser.on(short, long, *desc) do |v|
      @options[name] = (block_given? ? yield(v) : true)
    end
    # Widen the summary width if needed
    width = 2 + (short ? 4 : 0) + long.to_s.size
    @parser.summary_width = [@parser.summary_width, width].max
  end

  # Get the usage info string
  def usage
    str = "NAME\n"
    str += "    #@appname\n\n"
    unless @description.empty?
      str += "DESCRIPTION\n"
      str += @description.join + "\n"
    end
    unless @examples.empty?
      str += "EXAMPLES\n"
      str += @examples.join + "\n"
    end
    str += "OPTIONS"
    str += @parser.to_s.rstrip + "\n"
    str
  end

  # Parse an arguments array and return a new CommandLine object
  def self.parse(argv = ARGV)
    CommandLine.new.parse(argv)
  end

  # Parse an arguments array and populate this CommandLine object.
  # - Will print usage info and exit if help is requested.
  # - Will print an error message and abort if required inputs are missing.
  def parse(argv = ARGV)
    # Work off a copy of the arg array
    argv = argv.dup

    # Parse options and check for errors, or a help request
    print_usage_and_exit if argv.empty? && STDIN.tty?
    @parser.parse!(argv)
    @positional = argv
    print_usage_and_exit if self.help

    # Return self
    self
  end

  # Does what you think
  def print_usage_and_exit
    puts usage
    exit
  end

  # Look up an option's value and return it
  def method_missing(method_sym, *arguments, &block)
    return @options[method_sym] if @options.include?(method_sym)
    super
  end
end
