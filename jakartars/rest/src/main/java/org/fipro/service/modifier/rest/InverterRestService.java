package org.fipro.service.modifier.rest;

import java.util.List;
import java.util.stream.Collectors;

import org.fipro.service.modifier.api.StringModifier;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ServiceScope;
import org.osgi.service.jakartars.whiteboard.propertytypes.JSONRequired;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsResource;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Component(service=InverterRestService.class, scope = ServiceScope.PROTOTYPE)
@JakartarsResource
@JSONRequired
@Path("/")
@Produces(MediaType.APPLICATION_JSON)
public class InverterRestService {

    @Reference
    private volatile List<StringModifier> modifier;

    @GET
    @Path("modify/{input}")
    public List<String> modify(@PathParam("input") String input) {
		return modifier.stream()
				.map(mod -> mod.modify(input))
				.collect(Collectors.toList());
	}
}