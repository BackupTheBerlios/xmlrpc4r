
def require(file)
  if file =~ /^xmlrpc\/(.*)$/
    file = "../lib/#$1"
    p file
    super(file)
  else
    super
  end 
end


require "runit/cui/testrunner"
require "test_datetime"
require "test_parser"
require "test_features"


RUNIT::CUI::TestRunner.run(Test_DateTime.suite)
RUNIT::CUI::TestRunner.run(Test_Parser.suite)
RUNIT::CUI::TestRunner.run(Test_Features.suite)

