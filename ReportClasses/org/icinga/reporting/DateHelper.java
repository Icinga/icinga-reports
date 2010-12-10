package org.icinga.reporting;

import java.sql.Timestamp;
import java.util.Calendar;
import java.util.Date;

/**
 * Class helping jasper to generate reports for the following periods 
 * - last week 
 * - last month 
 * - last year
 * 
 * @version 0.2
 * @author berk
 * 
 */
public class DateHelper {

	static public Timestamp getLastWeekStart() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		cal.set(Calendar.DAY_OF_WEEK , Calendar.MONDAY);
		cal.add(Calendar.DAY_OF_YEAR, -7);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}

	static public Timestamp getLastWeekEnd() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		cal.set(Calendar.DAY_OF_WEEK , Calendar.SUNDAY);
		cal.add(Calendar.DAY_OF_YEAR, -7);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}

	static public Timestamp getLastMonthStart() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		cal.add(Calendar.MONTH, -1);
		cal.set(Calendar.DAY_OF_MONTH, 1);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}

	static public Timestamp getLastMonthEnd() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		cal.set(Calendar.DAY_OF_MONTH, 1);
		cal.add(Calendar.DAY_OF_MONTH, -1);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}

	static public Timestamp getLastYearStart() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		cal.add(Calendar.YEAR, -1);
		cal.set(Calendar.WEEK_OF_YEAR, 1);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}

	static public Timestamp getLastYearEnd() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		cal.set(Calendar.DAY_OF_YEAR, 1);
		cal.add(Calendar.DAY_OF_MONTH, -1);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}
}
