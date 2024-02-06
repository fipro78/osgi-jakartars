package org.fipro.service.modifier.rest;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.util.List;

import org.osgi.service.component.annotations.Reference;
import org.osgi.service.log.Logger;
import org.osgi.service.log.LoggerFactory;
import org.osgi.util.converter.Converter;
import org.osgi.util.converter.ConverterFunction;
import org.osgi.util.converter.Converters;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.ext.MessageBodyReader;
import jakarta.ws.rs.ext.MessageBodyWriter;

@Consumes(MediaType.WILDCARD) // NOTE: required to support "non-standard" JSON variants
@Produces(MediaType.APPLICATION_JSON)
public class JacksonJsonConverter implements MessageBodyReader<Object>, MessageBodyWriter<Object> {

	@Reference(service = LoggerFactory.class)
	private Logger logger;

	private final Converter converter = Converters.newConverterBuilder()
			.rule(String.class, this::toJson)
			.rule(this::toObject)
			.build();

	private ObjectMapper mapper = new ObjectMapper();

	private String toJson(Object value, Type targetType) {
		try {
			return mapper.writeValueAsString(value);
		} catch (JsonProcessingException e) {
			logger.error("error on JSON creation", e);
			return e.getLocalizedMessage();
		}
	}

	private Object toObject(Object o, Type t) {
		try {
			if (List.class.getName().equals(t.getTypeName())) {
				return this.mapper.readValue((String) o, List.class);
			}
			return this.mapper.readValue((String) o, String.class);
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