package org.icinga.reporting;

import java.sql.Timestamp;
import java.util.Calendar;
import java.util.Date;

/**
 * Class helping jasper to generate reports for the following periods 
 * - last week 
 * - last month 
 * - current month 
 * - last quarter 
 * - last year
 * 
 * @version 1.4
 * @author berk
 * @author dgoetz
 * 
 */
public class DateHelper {
	
	public static void main(String[] args) {
		/* main class for demo-output to check calendar on various systems */
		System.out.println("Last-Week Start: " + getLastWeekStart());
		System.out.println("Last-Week End: " + getLastWeekEnd());
		System.out.println("Last-Month Start: " + getLastMonthStart());
		System.out.println("Last-Month End: " + getLastMonthEnd());
		System.out.println("Last-Quarter Start: " + getLastQuarterStart());
		System.out.println("Last-Quarter End: " + getLastQuarterEnd());
		System.out.println("Last-Year Start: " + getLastYearStart());
		System.out.println("Last-Year End: " + getLastYearEnd());
		System.out.println("Current-Month Start: " + getCurrentMonthStart());
		System.out.println("Now: " + getNow());
	}

	static public Timestamp getCurrentMonthStart() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		cal.set(Calendar.DAY_OF_MONTH, 1);
		cal.set(Calendar.HOUR_OF_DAY, 0);
		cal.set(Calendar.MINUTE, 0);
		cal.set(Calendar.SECOND, 0);
		cal.set(Calendar.MILLISECOND, 0);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}

	static public Timestamp getNow() {
	  Calendar cal = Calendar.getInstance();
	  cal.setTime(new Date());
	  Timestamp ts = new Timestamp(cal.getTime().getTime());
	  return ts;
	}


	static public Timestamp getLastWeekStart() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		cal.add(Calendar.WEEK_OF_YEAR, -1);
		cal.setFirstDayOfWeek(Calendar.MONDAY);
		cal.setMinimalDaysInFirstWeek(1);
		cal.set(Calendar.DAY_OF_WEEK, Calendar.MONDAY);
		cal.set(Calendar.HOUR_OF_DAY, 0);
		cal.set(Calendar.MINUTE, 0);
		cal.set(Calendar.SECOND, 0);
		cal.set(Calendar.MILLISECOND, 0);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}

	static public Timestamp getLastWeekEnd() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		cal.add(Calendar.WEEK_OF_YEAR, -1);
		cal.setFirstDayOfWeek(Calendar.MONDAY);
		cal.setMinimalDaysInFirstWeek(1);
		cal.set(Calendar.DAY_OF_WEEK, Calendar.SUNDAY);
		cal.set(Calendar.HOUR_OF_DAY, 23);
		cal.set(Calendar.MINUTE, 59);
		cal.set(Calendar.SECOND, 59);
		cal.set(Calendar.MILLISECOND, 0);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}

	static public Timestamp getLastMonthStart() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		cal.add(Calendar.MONTH, -1);
		cal.set(Calendar.DAY_OF_MONTH, 1);
		cal.set(Calendar.HOUR_OF_DAY, 0);
		cal.set(Calendar.MINUTE, 0);
		cal.set(Calendar.SECOND, 0);
		cal.set(Calendar.MILLISECOND, 0);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}

	static public Timestamp getLastMonthEnd() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		cal.set(Calendar.DAY_OF_MONTH, 1);
		cal.add(Calendar.DAY_OF_MONTH, -1);
		cal.set(Calendar.HOUR_OF_DAY, 23);
		cal.set(Calendar.MINUTE, 59);
		cal.set(Calendar.SECOND, 59);
		cal.set(Calendar.MILLISECOND, 0);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}

	static public Timestamp getLastQuarterStart() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		switch(cal.get(Calendar.MONTH))
		{
			case Calendar.JANUARY: case Calendar.FEBRUARY: case Calendar.MARCH:
				cal.add(Calendar.YEAR, -1);
				cal.set(Calendar.MONTH, Calendar.OCTOBER);
				break;
			case Calendar.APRIL: case Calendar.MAY: case Calendar.JUNE:
				cal.set(Calendar.MONTH, Calendar.JANUARY);
				break;
			case Calendar.JULY: case Calendar.AUGUST: case Calendar.SEPTEMBER:
				cal.set(Calendar.MONTH, Calendar.APRIL);
				break;
			case Calendar.OCTOBER: case Calendar.NOVEMBER: case Calendar.DECEMBER:
				cal.set(Calendar.MONTH, Calendar.JULY);
				break;
		}
		cal.set(Calendar.DAY_OF_MONTH, 1);
		cal.set(Calendar.HOUR_OF_DAY, 0);
		cal.set(Calendar.MINUTE, 0);
		cal.set(Calendar.SECOND, 0);
		cal.set(Calendar.MILLISECOND, 0);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}	

	static public Timestamp getLastQuarterEnd() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		switch(cal.get(Calendar.MONTH))
		{
			case Calendar.JANUARY: case Calendar.FEBRUARY: case Calendar.MARCH:
				cal.add(Calendar.YEAR, -1);
				cal.set(Calendar.MONTH, Calendar.DECEMBER);
				break;
			case Calendar.APRIL: case Calendar.MAY: case Calendar.JUNE:
				cal.set(Calendar.MONTH, Calendar.MARCH);
				break;
			case Calendar.JULY: case Calendar.AUGUST: case Calendar.SEPTEMBER:
				cal.set(Calendar.MONTH, Calendar.JUNE);
				break;
			case Calendar.OCTOBER: case Calendar.NOVEMBER: case Calendar.DECEMBER:
				cal.set(Calendar.MONTH, Calendar.SEPTEMBER);
				break;
		}
		cal.add(Calendar.MONTH, 1);
		cal.set(Calendar.DAY_OF_MONTH, 1);
		cal.add(Calendar.DAY_OF_MONTH, -1);
		cal.set(Calendar.HOUR_OF_DAY, 23);
		cal.set(Calendar.MINUTE, 59);
		cal.set(Calendar.SECOND, 59);
		cal.set(Calendar.MILLISECOND, 0);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}	

	static public Timestamp getLastYearStart() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		cal.add(Calendar.YEAR, -1);
		cal.set(Calendar.DAY_OF_YEAR, 1);
		cal.set(Calendar.HOUR_OF_DAY, 0);
		cal.set(Calendar.MINUTE, 0);
		cal.set(Calendar.SECOND, 0);
		cal.set(Calendar.MILLISECOND, 0);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}

	static public Timestamp getLastYearEnd() {
		Calendar cal = Calendar.getInstance();
		cal.setTime(new Date());
		cal.set(Calendar.DAY_OF_YEAR, 1);
		cal.add(Calendar.DAY_OF_MONTH, -1);
		cal.set(Calendar.HOUR_OF_DAY, 23);
		cal.set(Calendar.MINUTE, 59);
		cal.set(Calendar.SECOND, 59);
		cal.set(Calendar.MILLISECOND, 0);
		Timestamp ts = new Timestamp(cal.getTime().getTime());
		return ts;
	}
}
