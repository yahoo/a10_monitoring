#! /usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../../src', __FILE__)
require 'a10_monitoring'

#===============================================================================
# Application usage and options
#===============================================================================

DESCRIPTION = <<-STR
Check A10 load balancer memory usage. Returns:

CRITICAL if % usage > critical-threshold
WARNING  if % usage > warning-threshold
OK       otherwise
STR

EXAMPLES = <<-STR
__APPNAME__ [options]
STR

cli = CommandLine.new(:description => DESCRIPTION, :examples => EXAMPLES)

cli.option(:slb, '-s', '--slb HOST[:PORT]', "SLB host and port. Assumes port 80 if not specified.") do |v|
  v
end
cli.option(:warning_threshold, '-w', '--warning PCT', 'Warning threshold, as percent (0-100)', 80) do |v|
  Float(v)
end
cli.option(:critical_threshold, '-c', '--critical PCT', 'Critical threshold, as percent (0-100)', 90) do |v|
  Float(v)
end
cli.option(:verbose, '-v', '--verbose', "Enable verbose output, including backtraces.") do
  true
end
cli.option(:version, nil, '--version', "Print the version string and exit.") do
  puts A10_MONITORING_VERSION_MESSAGE
  exit
end

#===============================================================================
# Main
#===============================================================================

slb = nil

begin
  # Parse command-line arguments
  cli.parse
  raise ArgumentError, 'please specify the SLB host:port'  unless cli.slb
  raise ArgumentError, 'please specify warning threshold'  unless cli.warning_threshold
  raise ArgumentError, 'please specify critical threshold' unless cli.critical_threshold

  # Construct the status message
  slb     = A10LoadBalancer.new(cli.slb)
  percent = slb.memory_percent_used
  used    = Utils.pretty_size(slb.memory_bytes_used, :bytes)
  total   = Utils.pretty_size(slb.memory_bytes_total, :bytes)
  message = "memory usage is %0.1f%% (%s of %s)" % [percent, used, total]

  # Return the proper status
  Icinga.quit(Icinga::CRITICAL, message) if percent > cli.critical_threshold
  Icinga.quit(Icinga::WARNING,  message) if percent > cli.warning_threshold
  Icinga.quit(Icinga::OK,       message)

rescue => e
  Utils.print_backtrace(e) if cli.verbose
  Icinga::quit(Icinga::CRITICAL, "#{e.class.name}: #{e.message}")
ensure
  slb.close_session if slb
end
