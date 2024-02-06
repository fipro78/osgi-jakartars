package org.fipro.service.modifier.rest;

import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.ServiceScope;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsExtension;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsMediaType;

import jakarta.ws.rs.core.Feature;
import jakarta.ws.rs.core.FeatureContext;
import jakarta.ws.rs.core.MediaType;

@Component(scope = ServiceScope.PROTOTYPE)
@JakartarsExtension
@JakartarsMediaType(MediaType.APPLICATION_JSON)
public class JacksonJsonFeature implements Feature {

	@Override
	public boolean configure(FeatureContext context) {
		context.register(JacksonJsonConverter.class);
		return true;
	}
}
