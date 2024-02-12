package org.fipro.service.modifier.rest;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.List;
import java.util.stream.Collectors;

import org.fipro.service.modifier.api.StringModifier;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ServiceScope;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsName;
//import org.osgi.service.jakartars.whiteboard.propertytypes.JSONRequired;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsResource;
//import org.osgi.service.servlet.whiteboard.propertytypes.HttpWhiteboardResource;

import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.FormParam;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.EntityPart;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;

@Component(
		service = ModifierRestService.class, 
		scope = ServiceScope.PROTOTYPE,
		// use component properties instead of component property type annotation
		// this way we avoid the requirement on the Servlet Whiteboard and the service also works on a Jetty
		property = {
				"osgi.http.whiteboard.resource.pattern=/files/*",
				"osgi.http.whiteboard.resource.prefix=static"
		})
//@HttpWhiteboardResource(pattern = "/files/*", prefix = "static")
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
		return modifier.stream().map(mod -> mod.modify(input)).collect(Collectors.toList());
	}

	@GET
	@Path("modifyhtml/{input}")
	@Produces(MediaType.TEXT_HTML)
	@HtmlModification
	public String modifyHtml(@PathParam("input") String input) {
		return modifier.stream().map(mod -> mod.modify(input)).collect(Collectors.joining(";"));
	}

	@GET
	@Path("pretty/{input}")
	public Result pretty(@PathParam("input") String input) {
		List<String> result = modifier.stream().map(mod -> mod.modify(input)).collect(Collectors.toList());

		return new Result(input, result);
	}

	// get the EntityPart and the InputStream form parameter with name "file"
	// received by a multipart/form-data POST request
	@POST
	@Path("modify/upload")
	@Consumes(MediaType.MULTIPART_FORM_DATA)
	@Produces(MediaType.TEXT_PLAIN)
	public Response upload(
			@FormParam("file") EntityPart part,
			@FormParam("file") InputStream input) throws IOException {
		
		
	    if (part != null
	            && part.getFileName().isPresent()) {

	        StringBuilder inputBuilder = new StringBuilder();
	        try (InputStream is = input;
	                BufferedReader br =
	                    new BufferedReader(new InputStreamReader(is))) {

	            String line;
	            while ((line = br.readLine()) != null) {
	                inputBuilder.append(line).append("\n");
	            }
	        }

	        // modify file content
	        String inputString = inputBuilder.toString();
	        List<String> modified = modifier.stream()
	            .map(mod -> mod.modify(inputString))
	            .collect(Collectors.toList());

	        String resultString = part.getFileName().get() + "\n\n";
	        resultString += String.join("\n", modified);
	        
	        return Response.ok(resultString).build();
	    }

	    return Response.status(Status.PRECONDITION_FAILED).build();
	}

	@POST
	@Path("modify/change")
	@Consumes(MediaType.MULTIPART_FORM_DATA)
	@Produces(MediaType.MULTIPART_FORM_DATA)
	public Response change(
			@FormParam("file") EntityPart part,
			@FormParam("file") InputStream input) throws IOException {
		
		
		if (part != null
				&& part.getFileName().isPresent()) {
			
			StringBuilder inputBuilder = new StringBuilder();
			try (InputStream is = input;
					BufferedReader br =
							new BufferedReader(new InputStreamReader(is))) {
				
				String line;
				while ((line = br.readLine()) != null) {
					inputBuilder.append(line).append("\n");
				}
			}
			
			// modify file content
			String inputString = inputBuilder.toString();
			List<String> modified = modifier.stream()
					.map(mod -> mod.modify(inputString))
					.collect(Collectors.toList());
			
			String resultString = String.join("\n", modified);
			
			return Response
					.ok(EntityPart
							.withFileName("changed.txt")
							.content(resultString)
							.build())
					.build();
		}
		
		return Response.status(Status.PRECONDITION_FAILED).build();
	}
	
	public static record Result(String input, List<String> result) {};
}