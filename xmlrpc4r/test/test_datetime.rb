#! /usr/bin/env ruby

#
# Testcase for file "datetime.rb"
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: test_datetime.rb,v 1.1 2001/02/07 17:06:38 michael Exp $
#



require "runit/testcase"
require "xmlrpc/datetime.rb"

class Test_DateTime < RUNIT::TestCase

  def test_new
    dt = createDateTime

    assert_instance_of(XMLRPC::DateTime, dt)
  end

  def test_get_values
    y, m, d, h, mi, s = 1970, 3, 24, 12, 0, 5
    dt = XMLRPC::DateTime.new(y, m, d, h, mi, s)

    assert_equal(y, dt.year)
    assert_equal(m, dt.month)
    assert_equal(m, dt.mon)
    assert_equal(d, dt.day)

    assert_equal(h, dt.hour)
    assert_equal(mi,dt.min)
    assert_equal(s, dt.sec)
  end

  def test_set_values
    dt = createDateTime
    y, m, d, h, mi, s = 1950, 12, 9, 8, 52, 30

    dt.year  = y
    dt.month = m
    dt.day   = d
    dt.hour  = h
    dt.min   = mi
    dt.sec   = s

    assert_equal(y, dt.year)
    assert_equal(m, dt.month)
    assert_equal(m, dt.mon)
    assert_equal(d, dt.day)

    assert_equal(h, dt.hour)
    assert_equal(mi,dt.min)
    assert_equal(s, dt.sec)

    dt.mon = 5
    assert_equal(5, dt.month)
    assert_equal(5, dt.mon)
  end

  def test_to_a
    y, m, d, h, mi, s = 1970, 3, 24, 12, 0, 5
    dt = XMLRPC::DateTime.new(y, m, d, h, mi, s)
    a = dt.to_a 

    assert_instance_of(Array, a)
    assert_equal(6,  a.size, "Returned array has wrong size")

    assert_equal(y,  a[0])
    assert_equal(m,  a[1])
    assert_equal(d,  a[2])
    assert_equal(h,  a[3])
    assert_equal(mi, a[4])
    assert_equal(s,  a[5])
  end

  def test_to_time1
    y, m, d, h, mi, s = 1970, 3, 24, 12, 0, 5
    dt = XMLRPC::DateTime.new(y, m, d, h, mi, s)
    time = dt.to_time 
    
    assert_not_nil(time)

    assert_equal(y,  time.year)
    assert_equal(m,  time.month)
    assert_equal(d,  time.day)
    assert_equal(h,  time.hour)
    assert_equal(mi, time.min)
    assert_equal(s,  time.sec)
  end

  def test_to_time2
    dt = createDateTime
    dt.year = 1969
    
    assert_nil(dt.to_time)
  end

  def test_to_date1
    y, m, d, h, mi, s = 1970, 3, 24, 12, 0, 5
    dt = XMLRPC::DateTime.new(y, m, d, h, mi, s)
    date = dt.to_date 
 
    assert_equal(y, date.year)
    assert_equal(m, date.month)
    assert_equal(d, date.day)
  end

  def test_to_date2
    dt = createDateTime
    dt.year = 666
    
    assert_equal(666, dt.to_date.year)
  end


  def createDateTime
    XMLRPC::DateTime.new(1970, 3, 24, 12, 0, 5)
  end

end
 
if $0 == __FILE__
  require "runit/cui/testrunner"
  RUNIT::CUI::TestRunner.run(Test_DateTime.suite)
end    
  
