
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


RUNIT::CUI::TestRunner.run(Test_DateTime.suite)

