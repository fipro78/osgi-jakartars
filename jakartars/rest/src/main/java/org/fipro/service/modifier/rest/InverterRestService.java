package org.fipro.service.modifier.rest;

import org.fipro.service.modifier.api.StringModifier;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsResource;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;

@JakartarsResource
@Component(service=InverterRestService.class)
@Path("/")
public class InverterRestService {

    @Reference
    StringModifier modifier;

    @GET
    @Path("modify/{input}")
    public String modify(@PathParam("input") String input) {
        return modifier.modify(input);
    }
}