package org.icinga.reporting.database;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.logging.Logger;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;

/**
 * this class is responsible for database connections 
 * configured in the servlet- or application context
 * 
 * @author Bernd Erk
 * @version 0.9
 */
public class ConnectionManager {
	Logger logger;

	public Connection getTomcatConnection(String connectionName) {
		DataSource ds;
		Connection conn = null;
		
		//get logger
		logger = Logger.getLogger("icinga");
		
		//try to get tomcat context and database connection
		try {
			Context initContext = new InitialContext();
			Context envContext = (Context) initContext.lookup("java:/comp/env");
			ds = (DataSource) envContext.lookup(connectionName);
			conn = ds.getConnection();
		} catch (NamingException ne) {
			logger.severe("not able to get datasource from context with: " + ne.toString());
				
		} catch (SQLException se) {
			logger.severe("not able to open database connection with: " + se.toString());
		}
		return conn;
	}

}
