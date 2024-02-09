package org.fipro.service.modifier.rest;

import java.util.List;
import java.util.stream.Collectors;

import org.fipro.service.modifier.api.StringModifier;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ServiceScope;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsName;
//import org.osgi.service.jakartars.whiteboard.propertytypes.JSONRequired;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsResource;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Component(service=ModifierRestService.class, scope = ServiceScope.PROTOTYPE)
@JakartarsResource
@JakartarsName("modifier")
// We don't use @JSONRequired, as we use the JacksonFeature provided by Jetty, 
// which does not provide the corresponding capability via @JakartarsMediaType(MediaType.APPLICATION_JSON)
// @JSONRequired
@Path("/")
@Produces(MediaType.APPLICATION_JSON)
public class ModifierRestService {
    
    @Reference
    private volatile List<StringModifier> modifier;

    @GET
    @Path("modify/{input}")
    public List<String> modify(@PathParam("input") String input) {
		return modifier.stream()
				.map(mod -> mod.modify(input))
				.collect(Collectors.toList());
	}
    
    @GET
    @Path("modifyhtml/{input}")
    @Produces(MediaType.TEXT_HTML)
    @HtmlModification
    public String modifyHtml(@PathParam("input") String input) {
    	return modifier.stream()
    			.map(mod -> mod.modify(input))
    			.collect(Collectors.joining(";"));
    }

    @GET
    @Path("pretty/{input}")
    public Result pretty(@PathParam("input") String input) {
    	List<String> result = modifier.stream()
    			.map(mod -> mod.modify(input))
    			.collect(Collectors.toList());
    	
    	return new Result(input, result);
    }
    
    public static record Result(String input, List<String> result) {};
}