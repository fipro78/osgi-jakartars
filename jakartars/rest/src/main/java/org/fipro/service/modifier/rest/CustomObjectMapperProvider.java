package org.fipro.service.modifier.rest;

import org.osgi.service.component.annotations.Component;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsExtension;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;

import jakarta.ws.rs.ext.ContextResolver;
import jakarta.ws.rs.ext.Provider;

@JakartarsExtension
@Component
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