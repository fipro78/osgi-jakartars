package org.fipro.service.modifier.impl;

import org.fipro.service.modifier.api.StringModifier;
import org.osgi.service.component.annotations.Component;

@Component
public class Upper implements StringModifier {

	@Override
	public String modify(String input) {
		return input.toUpperCase();
	}
}