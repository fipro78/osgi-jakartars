package org.fipro.service.modifier.rest;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.util.List;

import org.osgi.util.converter.Converter;
import org.osgi.util.converter.ConverterFunction;
import org.osgi.util.converter.Converters;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.ext.MessageBodyReader;
import jakarta.ws.rs.ext.MessageBodyWriter;
import jakarta.ws.rs.ext.Provider;
import jakarta.ws.rs.ext.Providers;

@Consumes(MediaType.WILDCARD)
@Produces(MediaType.APPLICATION_JSON)
@Provider
public class JacksonJsonConverter implements MessageBodyReader<Object>, MessageBodyWriter<Object> {

	private Logger logger = LoggerFactory.getLogger(JacksonJsonConverter.class);

	private final Converter converter = Converters.newConverterBuilder()
			.rule(String.class, this::toJson)
			.rule(this::toObject)
      .build();

	@Context
    private Providers providers;
	
	private ObjectMapper mapper;
	
	private ObjectMapper getObjectMapper() {
		if (this.mapper == null) {
			if (providers != null) {
				this.mapper = providers
						.getContextResolver(ObjectMapper.class, MediaType.APPLICATION_JSON_TYPE)
						.getContext(ObjectMapper.class);
			} else {
				this.mapper = new ObjectMapper();
			}
		}
		
		return this.mapper;
	}

	private String toJson(Object value, Type targetType) {
		try {
			return getObjectMapper().writeValueAsString(value);
		} catch (JsonProcessingException e) {
			logger.error("error on JSON creation", e);
			return e.getLocalizedMessage();
		}
	}

	private Object toObject(Object o, Type t) {
		try {
			if (List.class.getName().equals(t.getTypeName())) {
				return getObjectMapper().readValue((String) o, List.class);
			}
			return getObjectMapper().readValue((String) o, String.class);
		} catch (IOException e) {
			logger.error("error on JSON parsing", e);
		}
		return ConverterFunction.CANNOT_HANDLE;
	}

	@Override
	public boolean isWriteable(Class<?> c, Type t, Annotation[] a, MediaType mediaType) {

		return MediaType.APPLICATION_JSON_TYPE.isCompatible(mediaType) 
				|| mediaType.getSubtype().endsWith("+json");
	}

	@Override
	public boolean isReadable(Class<?> c, Type t, Annotation[] a, MediaType mediaType) {

		return MediaType.APPLICATION_JSON_TYPE.isCompatible(mediaType) 
				|| mediaType.getSubtype().endsWith("+json");
	}

	@Override
	public void writeTo(
			Object o, Class<?> type, Type genericType, 
			Annotation[] annotations, MediaType mediaType,
			MultivaluedMap<String, Object> httpHeaders, OutputStream out) 
					throws IOException, WebApplicationException {

		String json = converter.convert(o).to(String.class);
		out.write(json.getBytes());
	}

	@Override
	public Object readFrom(
			Class<Object> type, Type genericType, 
			Annotation[] annotations, MediaType mediaType,
			MultivaluedMap<String, String> httpHeaders, InputStream in) 
					throws IOException, WebApplicationException {

		BufferedReader reader = new BufferedReader(new InputStreamReader(in));
		return converter.convert(reader.readLine()).to(genericType);
	}
}