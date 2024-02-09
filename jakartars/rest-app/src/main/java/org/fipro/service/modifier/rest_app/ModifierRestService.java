package org.fipro.service.modifier.rest_app;

import java.util.List;
import java.util.stream.Collectors;

import org.fipro.service.modifier.api.StringModifier;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ServiceScope;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsResource;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Component(service=ModifierRestService.class, scope = ServiceScope.PROTOTYPE)
@JakartarsResource
@TargetModifyApp
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
    @Path("pretty/{input}")
    public Result pretty(@PathParam("input") String input) {
    	List<String> result = modifier.stream()
    			.map(mod -> mod.modify(input))
    			.collect(Collectors.toList());
    	
    	return new Result(input, result);
    }
    
    public static record Result(String input, List<String> result) {};
}