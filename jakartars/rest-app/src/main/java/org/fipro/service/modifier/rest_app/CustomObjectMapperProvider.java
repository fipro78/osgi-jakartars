package org.fipro.service.modifier.rest_app;

import org.osgi.service.component.annotations.Component;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsExtension;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsName;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;

import jakarta.ws.rs.ext.ContextResolver;
import jakarta.ws.rs.ext.Provider;

// We register this Extension as Whiteboard Service to verify that the interaction between 
// plain Jakarta-RS Resource and an Extension provided as Whiteboard Service works. 
// Typically you would keep this class also as plain Jakarta-RS Extension without the 
// OSGi service annotations and register it together with the JacksonJsonConverter 
// in the custom Application.

@Component
@JakartarsExtension
@JakartarsName("objectMapperProvider")
@TargetModifyApp
@Provider
public class CustomObjectMapperProvider implements ContextResolver<ObjectMapper> {

	private ObjectMapper mapper;

	public CustomObjectMapperProvider() {
		this.mapper = new ObjectMapper();
		this.mapper.enable(SerializationFeature.INDENT_OUTPUT);
	}

	public ObjectMapper getContext(Class<?> clazz) {
		return mapper;
	}
}