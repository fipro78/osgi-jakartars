package org.fipro.service.modifier.rest;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.util.List;

import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ServiceScope;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsExtension;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsMediaType;
import org.osgi.service.log.Logger;
import org.osgi.service.log.LoggerFactory;
import org.osgi.util.converter.Converter;
import org.osgi.util.converter.ConverterFunction;
import org.osgi.util.converter.Converters;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.ext.MessageBodyReader;
import jakarta.ws.rs.ext.MessageBodyWriter;

@Component(scope = ServiceScope.PROTOTYPE)
@JakartarsExtension
@JakartarsMediaType(MediaType.APPLICATION_JSON)
public class JacksonJsonConverter<T> implements MessageBodyReader<T>, MessageBodyWriter<T> {

    @Reference(service=LoggerFactory.class)
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
    public boolean isWriteable(
        Class<?> c, Type t, Annotation[] a, MediaType mediaType) {

        return MediaType.APPLICATION_JSON_TYPE.isCompatible(mediaType)
            || mediaType.getSubtype().endsWith("+json");
    }

    @Override
    public boolean isReadable(
        Class<?> c, Type t, Annotation[] a, MediaType mediaType) {

        return MediaType.APPLICATION_JSON_TYPE.isCompatible(mediaType)
            || mediaType.getSubtype().endsWith("+json");
    }

    @Override
    public void writeTo(
        T o, Class<?> arg1, Type arg2, Annotation[] arg3, MediaType arg4,
        MultivaluedMap<String, java.lang.Object> arg5, OutputStream out)
        throws IOException, WebApplicationException {

        String json = converter.convert(o).to(String.class);
        out.write(json.getBytes());
    }

    @SuppressWarnings("unchecked")
    @Override
    public T readFrom(
        Class<T> arg0, Type arg1, Annotation[] arg2, MediaType arg3,
        MultivaluedMap<String, String> arg4, InputStream in)
        throws IOException, WebApplicationException {

    	BufferedReader reader =
            new BufferedReader(new InputStreamReader(in));
        return (T) converter.convert(reader.readLine()).to(arg1);
    }
}