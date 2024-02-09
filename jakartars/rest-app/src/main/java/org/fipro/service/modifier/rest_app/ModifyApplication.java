package org.fipro.service.modifier.rest_app;

import java.util.Set;

import org.osgi.service.component.annotations.Component;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsApplicationBase;
import org.osgi.service.jakartars.whiteboard.propertytypes.JakartarsName;

import jakarta.ws.rs.core.Application;

@JakartarsApplicationBase("mod")
@JakartarsName("modifyApplication")
@Component(service=Application.class)
public class ModifyApplication extends Application {

    @Override
    public Set<Class<?>> getClasses() {
        return Set.of(JacksonJsonConverter.class);
    }
}