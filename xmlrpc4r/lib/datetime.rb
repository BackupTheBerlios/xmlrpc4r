=begin
= xmlrpc/datetime.rb
Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)

Released under the same term of license as Ruby.

= Classes
* ((<XMLRPC::DateTime>))

= XMLRPC::DateTime
== Description
This class is important to handle XMLRPC (('dateTime.iso8601')) values,
correcly, because normal UNIX-dates (class (({Date}))) only handle dates 
from year 1970 on, and class (({Time})) handles dates without the time
component. (({XMLRPC::DateTime})) is able to store a XMLRPC 
(('dateTime.iso8601')) value correctly.

== Class Methods
--- XMLRPC::DateTime.new( year, month, day, hour, min, sec )
    Creates a new (({XMLRPC::DateTime})) instance with the
    parameters ((|year|)), ((|month|)), ((|day|)) as date and 
    ((|hour|)), ((|min|)), ((|sec|)) as time.
    
== Instance Methods
--- XMLRPC::DateTime#year
--- XMLRPC::DateTime#month
--- XMLRPC::DateTime#day
--- XMLRPC::DateTime#hour
--- XMLRPC::DateTime#min
--- XMLRPC::DateTime#sec
    Return the value of the specified date/time component.

--- XMLRPC::DateTime#mon
    Alias for ((<XMLRPC::DateTime#month>)).

--- XMLRPC::DateTime#year=
--- XMLRPC::DateTime#month=
--- XMLRPC::DateTime#day=
--- XMLRPC::DateTime#hour=
--- XMLRPC::DateTime#min=
--- XMLRPC::DateTime#sec=
    Set the value of the specified date/time component.

--- XMLRPC::DateTime#mon=
    Alias for ((<XMLRPC::DateTime#month=>)).

--- XMLRPC::DateTime#to_time
    Return a (({Time})) object of the date/time which (({self})) represents.
    If the (('year')) is below 1970, this method returns (({nil})), 
    because (({Time})) cannot handle years below 1970.
    The used timezone is GMT.

--- XMLRPC::DateTime#to_date
    Return a (({Date})) object of the date which (({self})) represents.
    The (({Date})) object do ((*not*)) contain the time component (only date).

--- XMLRPC::DateTime#to_a
    Returns all date/time components in an array.
    Returns (({[year, month, day, hour, min, sec]})).
=end

require "date"

module XMLRPC

class DateTime
  
  attr_accessor :year, :month, :day, :hour, :min, :sec

  alias mon  month
  alias mon= month= 
 
  def initialize(year, month, day, hour, min, sec)
    @year  = year
    @month = month
    @day   = day
    @hour  = hour
    @min   = min
    @sec   = sec
  end
 
  def to_time
    if @year >= 1970
      Time.gm(*to_a)
    else
      nil
    end
  end

  def to_date
    Date.new(*to_a[0,3])
  end

  def to_a
    [@year, @month, @day, @hour, @min, @sec]
  end

end


end # module XMLRPC


=begin
= History
    $Id: datetime.rb,v 1.3 2001/02/05 22:18:58 michael Exp $
=end
