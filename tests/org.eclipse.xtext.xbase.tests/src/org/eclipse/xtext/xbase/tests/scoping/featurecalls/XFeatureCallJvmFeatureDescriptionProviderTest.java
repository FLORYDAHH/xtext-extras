/*******************************************************************************
 * Copyright (c) 2010 itemis AG (http://www.itemis.eu) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.xtext.xbase.tests.scoping.featurecalls;

import static com.google.common.collect.Sets.*;

import org.eclipse.xtext.common.types.JvmDeclaredType;
import org.eclipse.xtext.common.types.JvmTypeReference;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.xbase.scoping.featurecalls.DefaultJvmFeatureDescriptionProvider;
import org.eclipse.xtext.xbase.scoping.featurecalls.IJvmFeatureDescriptionProvider;
import org.eclipse.xtext.xbase.scoping.featurecalls.JvmFeatureScope;
import org.eclipse.xtext.xbase.scoping.featurecalls.XFeatureCallSugarDescriptionProvider;

import com.google.common.collect.Lists;

import testdata.VisibilitySubClass;
import testdata.VisibilitySuperType;


/**
 * @author Sven Efftinge - Initial contribution and API
 */
public class XFeatureCallJvmFeatureDescriptionProviderTest extends AbstractJvmFeatureScopeProviderTest {
	
	public void testNoContext() throws Exception {
		JvmTypeReference reference = getTypeRef(VisibilitySubClass.class.getCanonicalName());
		DefaultJvmFeatureDescriptionProvider defaultProvider = createDefaultJvmFeatureDescriptionProvider();
		XFeatureCallSugarDescriptionProvider descProvider = createXFeatureCallSugaringJvmFeatureDescriptionProvider();
		defaultProvider.setContextType(null); // NO Context!
		descProvider.setContextType(null); // NO Context!
		
		JvmFeatureScope scope = getFeatureProvider().createFeatureScopeForTypeRef(reference, 
				Lists.<IJvmFeatureDescriptionProvider>newArrayList(defaultProvider, descProvider));
		assertEquals(8, numberOfScopes(scope));

		assertSetsEqual(newHashSet("publicField", "publicMethod()", "getPublicProperty()","setPublicProperty(java.lang.String)"),	getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("wait(long)","toString()","getClass()","hashCode()","notify()","wait(long,int)","equals(java.lang.Object)","wait()","notifyAll()"),	getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("publicMethod", "publicProperty","getPublicProperty"), getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("class", "toString","getClass","hashCode","notify","wait","notifyAll"), getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("privateField", "protectedField","privateMethod()","setPrivateProperty(java.lang.String)","protectedMethod()","getPrivateProperty()","getProtectedProperty()","setProtectedProperty(java.lang.String)"), getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("registerNatives()","clone()","finalize()"), getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("privateMethod","protectedMethod","getPrivateProperty","privateProperty","getProtectedProperty","protectedProperty"), getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("registerNatives","clone","finalize"),	getSignatures(scope));
		assertSame(IScope.NULLSCOPE, scope.getParent());
	}
	
	public void testSubclassContext() throws Exception {
		JvmTypeReference reference = getTypeRef(VisibilitySubClass.class.getCanonicalName());
		
		DefaultJvmFeatureDescriptionProvider defaultProvider = createDefaultJvmFeatureDescriptionProvider();
		XFeatureCallSugarDescriptionProvider descProvider = createXFeatureCallSugaringJvmFeatureDescriptionProvider();
		defaultProvider.setContextType((JvmDeclaredType) reference.getType());
		descProvider.setContextType((JvmDeclaredType) reference.getType());
		
		JvmFeatureScope scope = getFeatureProvider().createFeatureScopeForTypeRef(reference, Lists.<IJvmFeatureDescriptionProvider>newArrayList(defaultProvider, descProvider));
		assertEquals(8, numberOfScopes(scope));
		
		assertSetsEqual(newHashSet("publicField", "publicMethod()", "getPublicProperty()","protectedField","protectedMethod()","getProtectedProperty()","setPublicProperty(java.lang.String)","setProtectedProperty(java.lang.String)"),	getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("wait(long)","toString()","getClass()","hashCode()","notify()","wait(long,int)","equals(java.lang.Object)","wait()","notifyAll()","clone()","finalize()"),	getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("publicMethod", "publicProperty","getPublicProperty","protectedMethod","getProtectedProperty","protectedProperty"), getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("class", "toString","getClass","hashCode","notify","wait","notifyAll","clone","finalize"), getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("privateField", "privateMethod()","getPrivateProperty()","setPrivateProperty(java.lang.String)"), getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("registerNatives()"), getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("privateMethod","getPrivateProperty","privateProperty"), getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("registerNatives"),	getSignatures(scope));
		assertSame(IScope.NULLSCOPE, scope.getParent());
	}
	
	public void testPrivateContext() throws Exception {
		JvmTypeReference reference = getTypeRef(VisibilitySubClass.class.getCanonicalName());
		JvmTypeReference superType = getTypeRef(VisibilitySuperType.class.getCanonicalName());
		
		DefaultJvmFeatureDescriptionProvider defaultProvider = createDefaultJvmFeatureDescriptionProvider();
		XFeatureCallSugarDescriptionProvider descProvider = createXFeatureCallSugaringJvmFeatureDescriptionProvider();
		defaultProvider.setContextType((JvmDeclaredType) superType.getType());
		descProvider.setContextType((JvmDeclaredType) superType.getType());
		
		JvmFeatureScope scope = getFeatureProvider().createFeatureScopeForTypeRef(reference, Lists.<IJvmFeatureDescriptionProvider>newArrayList(defaultProvider, descProvider));
		
		assertEquals(6, numberOfScopes(scope));
		
		assertSetsEqual(newHashSet("publicField", "publicMethod()", "getPublicProperty()","protectedField","protectedMethod()","getProtectedProperty()","privateField", "privateMethod()","getPrivateProperty()","setPrivateProperty(java.lang.String)","setProtectedProperty(java.lang.String)","setPublicProperty(java.lang.String)"),	getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("wait(long)","toString()","getClass()","hashCode()","notify()","wait(long,int)","equals(java.lang.Object)","wait()","notifyAll()","clone()","finalize()"),	getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("publicMethod", "publicProperty","getPublicProperty","protectedMethod","getProtectedProperty","protectedProperty","privateMethod","getPrivateProperty","privateProperty"), getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("class", "toString","getClass","hashCode","notify","wait","notifyAll","clone","finalize"), getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("registerNatives()"), getSignatures(scope));
		scope = (JvmFeatureScope) scope.getParent();
		assertSetsEqual(newHashSet("registerNatives"),	getSignatures(scope));
		assertSame(IScope.NULLSCOPE, scope.getParent());
	}
}
