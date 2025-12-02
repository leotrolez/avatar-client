

Date = {}

Date.Number = 1
Date.String = 2

function Date:getDay()
	return tonumber(os.date("%d")) 
end

function Date:getMonth()
	return tonumber(os.date('%m'))
end

function Date:getYear()
	return tonumber(os.date('%Y'))
end

function Date:getDayOfWeek(month, year)
  return os.date('*t',os.time{year = year, month = month, day = 0}).wday
end

function Date:isLeapYear(year)
  return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

function Date:getQtdDayOfMonth(month, year)
  local day = 31
  if ( month == 2 ) then
    day = Date:isLeapYear(year) and 29 or 28
  elseif ( month == 4 or month == 6 or month == 9 or month == 11 ) then
    day = day - 1    
  end
  return day
end