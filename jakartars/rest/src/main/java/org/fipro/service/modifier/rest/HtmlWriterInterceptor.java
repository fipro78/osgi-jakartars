package org.fipro.service.modifier.rest;

import java.io.IOException;

import org.osgi.service.component.annotations.Component;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsExtension;

import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.ext.WriterInterceptor;
import jakarta.ws.rs.ext.WriterInterceptorContext;

@Component
@JakartarsExtension
@HtmlModification
public class HtmlWriterInterceptor implements WriterInterceptor {

	public void aroundWriteTo(WriterInterceptorContext ctx) 
    		throws WebApplicationException, IOException {
        
    	Object entity = ctx.getEntity();
        
        if (entity instanceof String result) {
        	String html = "<html><head></head><body><ul>";
        	String[] split = result.split(";");
        	for (String string : split) {
        		html += "<li>" + string + "</li>";
			}
        	html += "</ul></body>";
        	ctx.setEntity(html);
        }
        ctx.proceed();
    }
}