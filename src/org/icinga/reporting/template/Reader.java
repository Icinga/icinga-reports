package org.icinga.reporting.template;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.design.JasperDesign;
import net.sf.jasperreports.engine.xml.JRXmlLoader;

/**
 * this class is responsible for template reading
 * 
 * @author Bernd Erk
 * @version 0.9
 */
public class Reader {
	
	public JasperDesign getTemplate(String reportFolder, String reportName) throws JRException {
		JasperDesign jasperDesign = JRXmlLoader.load(reportFolder  + reportName);
		return jasperDesign;
	}

}
