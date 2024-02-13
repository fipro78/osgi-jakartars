package org.fipro.service.modifier.rest;

import org.osgi.service.component.annotations.Component;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsExtension;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsMediaType;

import com.fasterxml.jackson.jakarta.rs.json.JacksonJsonProvider;

import jakarta.ws.rs.core.Feature;
import jakarta.ws.rs.core.FeatureContext;
import jakarta.ws.rs.core.MediaType;

@Component
@JakartarsExtension
@JakartarsMediaType(MediaType.APPLICATION_JSON)
public class JacksonJsonFeature implements Feature {

	@Override
	public boolean configure(FeatureContext context) {
		context.register(JacksonJsonProvider.class);
		return true;
	}
}