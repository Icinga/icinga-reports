package org.icinga.reporting;

import java.io.IOException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.logging.Logger;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import net.sf.jasperreports.engine.JRAbstractExporter;
import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JRExporterParameter;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.design.JasperDesign;
import net.sf.jasperreports.engine.export.JRCsvExporter;
import net.sf.jasperreports.engine.export.JRPdfExporter;
import net.sf.jasperreports.engine.export.JRRtfExporter;
import net.sf.jasperreports.engine.export.JRXhtmlExporter;
import net.sf.jasperreports.engine.export.JRXlsExporter;
import net.sf.jasperreports.engine.export.JRXmlExporter;
import net.sf.jasperreports.engine.export.oasis.JROdsExporter;
import net.sf.jasperreports.engine.export.oasis.JROdtExporter;

import org.icinga.reporting.data.Loader;
import org.icinga.reporting.template.Reader;

/**
 * this servlet takes the request parameters a executes the necessary
 * subclasses to generate given report in the requested format 
 *  
 * @author Bernd Erk
 * @version 0.9
 */
public class Generator extends HttpServlet {
	private static final long serialVersionUID = 1L;
	Logger logger;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public Generator() {
        super();
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	@SuppressWarnings("unchecked")
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		
		JasperDesign jasperDesign;
		JasperPrint jasperPrint;
		JRAbstractExporter jasperExport;
		HashMap parameterMap = new HashMap();
		
		//get logger
		logger = Logger.getLogger("icinga");
		
		//get parameters
		Map<String,String[]> parameters = request.getParameterMap();
		
		Iterator it = parameters.keySet().iterator();
		String key;
		while(it.hasNext()) {
			key = (String) it.next();
			parameterMap.put(key, ((String[]) parameters.get(key))[0]);
		}
		
		//get format
		String reportName = request.getParameter("reportName");
		String reportFormat = request.getParameter("reportFormat");
		String reportFile = request.getParameter("reportFile");
		
		//check basic parameters
		if(reportName == null || reportName.equalsIgnoreCase("")) {
			throw new ServletException("no report specified");
		}
		
		if(reportFormat == null || reportFormat.equalsIgnoreCase("")) {
			throw new ServletException("no format specified");
		}
		if(reportFile == null || reportFile.equalsIgnoreCase("")) {
			throw new ServletException("no name specified");
		}
		
		//get parameters from context
		String reportFolder = this.getServletContext().getInitParameter("IcingaReportFolder");
		String connectionName = this.getServletContext().getInitParameter("IcingaJdbcName");
		
		//get Template
		Reader reader = new Reader();
		try {
			jasperDesign = reader.getTemplate(reportFolder, reportName);
		}
		catch(JRException je) {
			logger.severe("not able to load report with: " + je.toString());
			throw new ServletException("not able to report template with: " + je.toString());
		}
		
		//fill report
		Loader loader = new Loader();
		jasperPrint = loader.createPrinter(jasperDesign, parameterMap, connectionName);
		
		//export report
		response.setContentType("application/x-download");
		response.setHeader("Content-Disposition", "attachment; filename=" + reportFile);

	    try {
	    	if(reportFormat.equalsIgnoreCase(Formats.pdf)) {
	    		jasperExport = new JRPdfExporter();
	    	}
	    	else if(reportFormat.equalsIgnoreCase(Formats.csv)) {
	    		jasperExport = new JRCsvExporter();
	    	}
	    	else if(reportFormat.equalsIgnoreCase(Formats.xhtml)) {
	    		jasperExport = new JRXhtmlExporter();
	    	}
	    	else if(reportFormat.equalsIgnoreCase(Formats.xml)) {
	    		jasperExport = new JRXmlExporter();
	    	}
	    	else if(reportFormat.equalsIgnoreCase(Formats.ods)) {
	    		jasperExport = new JROdsExporter();
	    	}
	    	else if(reportFormat.equalsIgnoreCase(Formats.odt)) {
	    		jasperExport = new JROdtExporter();
	    	}
	    	else if(reportFormat.equalsIgnoreCase(Formats.rtf)) {
	    		jasperExport = new JRRtfExporter();
	    	}
	    	else if(reportFormat.equalsIgnoreCase(Formats.xls)) {
	    		jasperExport = new JRXlsExporter();
	    	}
	    	else {
	    		throw new ServletException("given format not supported");
	    	}

		    //export report
		    jasperExport.setParameter(JRExporterParameter.JASPER_PRINT, jasperPrint);
		    jasperExport.setParameter(JRExporterParameter.OUTPUT_STREAM,response.getOutputStream());
		    jasperExport.exportReport();
	    }
	    catch(JRException je) {
	    	logger.severe("not able to export report with: " + je.toString());
	    	throw new ServletException("not able to export report with: " + je.toString());
	    }
	}

}
