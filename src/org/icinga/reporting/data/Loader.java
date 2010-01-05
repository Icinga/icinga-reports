package org.icinga.reporting.data;

import java.sql.Connection;
import java.util.HashMap;
import java.util.logging.Logger;

import org.icinga.reporting.database.ConnectionManager;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperCompileManager;
import net.sf.jasperreports.engine.JasperFillManager;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.JasperReport;
import net.sf.jasperreports.engine.design.JasperDesign;

/**
 * the loader class reads data from the given
 * database connection and fills up the report
 * 
 * @author Bernd Erk
 * @version 0.9 
 */
public class Loader {
	Logger logger;
	
	public JasperPrint createPrinter(JasperDesign jasperDesign, HashMap parameters, String connectionName) {
		JasperPrint jasperPrint = null;
		JasperReport jasperReport;
		Connection conn;
		
		//get logger
		logger = Logger.getLogger("icinga");
		
		//get connection
		ConnectionManager cManager = new ConnectionManager();
		conn = cManager.getTomcatConnection(connectionName);
		
		//fill report
		try {
			jasperReport = JasperCompileManager.compileReport(jasperDesign);
			jasperPrint = JasperFillManager.fillReport(jasperReport, parameters, conn);
		}
		catch(JRException je) {
			logger.severe("not able to fill report with: " + je.toString());
		}
		return jasperPrint;
	}
}
