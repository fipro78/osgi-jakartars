package org.fipro.service.modifier.crac;

import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;

import org.crac.CheckpointException;
import org.crac.Core;
import org.crac.RestoreException;
import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;

@Component
public class CheckpointCreationComponent {

    Logger logger = Logger.getLogger(CheckpointCreationComponent.class.getName());

    @Activate
    void activate() {
        Executors.newSingleThreadScheduledExecutor().schedule(() -> {
            try {
                Core.checkpointRestore();

                // Note:
                // any code written after checkpointRestore() will be executed on restore
                logger.info("Restored application at " + System.currentTimeMillis());

            } catch (CheckpointException|RestoreException|UnsupportedOperationException e) {
                // Note:
                // Only print the stacktrace to verify the execution and behavior in
                // different environments. In production we would probably catch the
                // UnsupportedOperationException silently.
                e.printStackTrace();
            }
        }, 
        10, TimeUnit.SECONDS);
    }
}