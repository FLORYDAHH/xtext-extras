/*******************************************************************************
 * Copyright (c) 2012 itemis AG (http://www.itemis.eu) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.xtext.xbase.tests.typesystem

import java.util.Set
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.xbase.XClosure
import org.eclipse.xtext.xbase.tests.AbstractXbaseTestCase
import org.junit.AfterClass
import org.junit.BeforeClass
import org.junit.Test

import static org.junit.Assert.*
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import java.util.List
import org.junit.Ignore

/**
 * @author Sebastian Zarnekow - Initial contribution and API
 */
abstract class AbstractClosureTypeTest extends AbstractXbaseTestCase {
	
	def List<Object> resolvesClosuresTo(String expression, String... types)
	
	def void withEquivalents(List<Object> references, String... type)
	
	static Set<String> seenExpressions
	
	@BeforeClass
	def static void createSeenExpressionsSet() {
		seenExpressions = newHashSet
	}
	
	@AfterClass
	def static void discardSeenExpressions() {
		seenExpressions = null
	}
	
	def protected findClosures(CharSequence expression) {
		val xExpression = expression(expression, false)
		val closures = EcoreUtil2::eAll(xExpression).filter(typeof(XClosure)).toList
		return closures.sortBy [ NodeModelUtils::findActualNodeFor(it).offset ]
	}
	
	override protected expression(CharSequence expression, boolean resolve) throws Exception {
		val string = expression.toString
		if (!seenExpressions.add(string)) {
			fail("Duplicate expression under test: " + expression)
		}
		super.expression(expression, resolve)
	}

	@Test def void testNumberLiteralInClosure() throws Exception {
		"newArrayList().map[42]".resolvesClosuresTo("(Object)=>int") // .withEquivalents("Function1<Object, Integer>")
	}
	
	@Test def void testOverloadedOperators_01() throws Exception {
		"(0..Math::sqrt(1l).intValue).filter[ i | 1l % i == 0 ].isEmpty".resolvesClosuresTo("(Integer)=>boolean")
	}
	
	@Test def void testOverloadedOperators_02() throws Exception {
		"(1..2).map[ toString ].reduce[ i1, i2| i1 + i2 ]".resolvesClosuresTo("(Integer)=>String", "(String, String)=>String")
	}
	
	@Test def void testOverloadedOperators_03() throws Exception {
		"(1..2).map[ toString.length ].reduce[ i1, i2| i1 + i2 ]".resolvesClosuresTo("(Integer)=>int", "(Integer, Integer)=>int")
	}
	
	@Test def void testOverloadedOperators_04() throws Exception {
		"(1..2).map[ new java.math.BigInteger(toString) ].reduce[ i1, i2| i1 + i2 ]".resolvesClosuresTo(
			"(Integer)=>BigInteger", "(BigInteger, BigInteger)=>BigInteger")
	}
	
	@Ignore("i1 and i2 should become T -> Object thus + maps to String + Object")
	@Test def void testOverloadedOperators_05() throws Exception {
		"(1..2).map[ new java.math.BigInteger(toString) ].reduce[ i1, i2 | i1.toString + i2 ]".resolvesClosuresTo(
			"(Integer)=>BigInteger", "(Object, Object)=>String")
	}
	
	@Ignore("i1 and i2 should become T -> Object thus + maps to Object + String")
	@Test def void testOverloadedOperators_06() throws Exception {
		"(1..2).map[ new java.math.BigInteger(toString) ].reduce[ i1, i2| i1 + String::valueOf(i2) ]".resolvesClosuresTo(
			"(Integer)=>BigInteger", "(Object, Object)=>String")
	}
	
	@Test def void testOverloadedOperators_07() throws Exception {
		"(1..2).map[ new java.math.BigInteger(toString) ].map[ i | i.toString + i ]".resolvesClosuresTo(
			"(Integer)=>BigInteger", "(BigInteger)=>String")
	}
	
	@Test def void testOverloadedOperators_08() throws Exception {
		"(1..2).map[ new java.math.BigInteger(toString) ].map[ i | i + String::valueOf(i) ]".resolvesClosuresTo(
			"(Integer)=>BigInteger", "(BigInteger)=>String")
	}
	
	@Test def void testOverloadedOperators_09() throws Exception {
		"(0..Math::sqrt(1l).intValue).filter[ i | 1l % i == 0 ].empty".resolvesClosuresTo(
			"(Integer)=>boolean")
	}

	@Test def void testMethodTypeParamInference_00() throws Exception {
		"new java.util.ArrayList<String>().findFirst(e | true)".resolvesClosuresTo("(String)=>boolean")
	}
	
	@Test def void testMethodTypeParamInference_01() throws Exception {
		"new java.util.ArrayList<String>().findFirst(e|e == 'foo')".resolvesClosuresTo("(String)=>boolean")
	}
	
	@Test def void testMethodTypeParamInference_02() throws Exception {
		"new java.util.ArrayList<String>().<String>findFirst(e|e == 'foo')".resolvesClosuresTo("(String)=>boolean")
	}
	
	@Test def void testMethodTypeParamInference_03() throws Exception {
		"new java.util.ArrayList<String>().findFirst(Object e|e == 'foo')".resolvesClosuresTo("(Object)=>boolean")
	}
	
	@Test def void testMethodTypeParamInference_04() throws Exception {
		"$$IterableExtensions::findFirst(new java.util.ArrayList<String>) [e | true]".resolvesClosuresTo("(String)=>boolean")
	}
	
	@Test def void testMethodTypeParamInference_05() throws Exception {
		"$$IterableExtensions::findFirst(new java.util.ArrayList<String>) [e|e == 'foo']".resolvesClosuresTo("(String)=>boolean")
	}
	
	@Test def void testMethodTypeParamInference_06() throws Exception {
		"$$IterableExtensions::<String>findFirst(new java.util.ArrayList<String>) [e|e == 'foo']".resolvesClosuresTo("(String)=>boolean")
	}
	
	@Test def void testMethodTypeParamInference_07() throws Exception {
		"$$IterableExtensions::<String>findFirst(new java.util.ArrayList<String>) [Object e|e == 'foo']".resolvesClosuresTo("(Object)=>boolean")
	}
	
	@Test def void testTypeForVoidClosure() throws Exception {
		"newArrayList('foo','bar').forEach []".resolvesClosuresTo("(String)=>void") // .withEquivalents("Procedure1<String>")
	}

	@Test def void testClosure_00() throws Exception {
		"[|'literal'].apply()".resolvesClosuresTo("()=>String")
	}
	
	@Test def void testClosure_01() throws Exception {
		"{ var closure = [|'literal']
		  new testdata.ClosureClient().invoke0(closure)	}".resolvesClosuresTo("()=>String")
	}
	
	@Test
	def void testClosure_02() throws Exception {
		("{\n" + 
		"  var java.util.List<? super String> list = null;\n" + 
		"  list.map(e|e)\n" +
		"}").resolvesClosuresTo("(Object)=>Object")
	}

	@Test
	def void testClosure_03() throws Exception {
		("{\n" + 
		"  var java.util.List<? super String> list = null;\n" + 
		"  list.map(e|false)\n" +
		"}").resolvesClosuresTo("(Object)=>boolean")
	}

	@Test def void testClosure_04() throws Exception {
		"{ 
			val mapper = [ x | x ]
			newArrayList(1).map(mapper)
		}".resolvesClosuresTo("(Integer)=>Integer")
	}
	
	@Test def void testClosure_05() throws Exception {
		"{ 
			val mapper = [ x | x ]
			newArrayList(1).map(mapper).head
		}".resolvesClosuresTo("(Integer)=>Integer")
	}
	
	@Test def void testClosure_06() throws Exception {
		"{ 
			val mapper = [ x | x ]
			newArrayList(1).map(mapper).findFirst [ true ]
		}".resolvesClosuresTo("(Integer)=>Integer", "(Integer)=>boolean")
	}
	
	@Ignore("TODO deferred closure body typing")
	@Test def void testClosure_07() throws Exception {
		"{ 
			val mapper = [ x | x.charAt(0) ]
			newArrayList('').map(mapper)
		}".resolvesClosuresTo("List<Character>")
	}
	
	@Test def void testClosure_08() throws Exception {
		"{ 
			val fun = [ x | x ]
			val String s = fun.apply(null)
			fun
		}".resolvesClosuresTo("(String)=>String").withEquivalents("Function1<String, String>")
	}
	
	@Test def void testClosure_09() throws Exception {
		"{ 
			val fun = [ x | x ]
			val java.util.List<String> list = newArrayList(fun.apply(null))
			fun
		}".resolvesClosuresTo("(String)=>String").withEquivalents("Function1<String, String>")
	}
	
	@Test def void testClosure_10() throws Exception {
		"{ 
			val fun = [ x | x ]
			val java.util.List<String> list = newArrayList.map(fun)
			fun
		}".resolvesClosuresTo("(String)=>String").withEquivalents("Function1<String, String>")
	}
	
	@Test def void testClosure_11() throws Exception {
		"{ 
			val fun = [ x | x ]
			val java.util.Set<String> list = newArrayList.map(fun)
			fun
		}".resolvesClosuresTo("(String)=>String").withEquivalents("Function1<String, String>")
	}
	
	@Test def void testClosure_12() throws Exception {
		"{ 
			val fun = [ x | x ]
			val java.util.ArrayList<String> list = newArrayList.map(fun)
			fun
		}".resolvesClosuresTo("(String)=>String").withEquivalents("Function1<String, String>")
	}
	
	@Test def void testClosure_13() throws Exception {
		"{ 
			val fun = [ x | x ]
			val Iterable<String> list = newArrayList.map(fun)
			fun
		}".resolvesClosuresTo("(String)=>String").withEquivalents("Function1<String, String>")
	}
	
	@Test def void testClosure_14() throws Exception {
		"{ 
			val fun = [ x | x ]
			val list = newArrayList.map(fun)
			val Iterable<String> iter = list
			fun
		}".resolvesClosuresTo("(String)=>String").withEquivalents("Function1<String, String>")
	}
	
	@Test def void testClosure_15() throws Exception {
		"{ 
			val fun = [ x | x ]
			val java.util.List<String> list = $$ListExtensions::map(newArrayList, fun)
			fun
		}".resolvesClosuresTo("(String)=>String").withEquivalents("Function1<String, String>")
	}
	
	@Test def void testClosure_16() throws Exception {
		"{ 
			val fun = [ x | x ]
			val java.util.Set<String> list = $$ListExtensions::map(newArrayList, fun)
			fun
		}".resolvesClosuresTo("(String)=>String").withEquivalents("Function1<String, String>")
	}
	
	@Test def void testClosure_17() throws Exception {
		"{ 
			val fun = [ x | x ]
			val java.util.ArrayList<String> list = $$ListExtensions::map(newArrayList, fun)
			fun
		}".resolvesClosuresTo("(String)=>String").withEquivalents("Function1<String, String>")
	}
	
	@Test def void testClosure_18() throws Exception {
		"{ 
			val fun = [ x | x ]
			val Iterable<String> list = $$ListExtensions::map(newArrayList, fun)
			fun
		}".resolvesClosuresTo("(String)=>String").withEquivalents("Function1<String, String>")
	}
	
	@Test def void testClosure_19() throws Exception {
		"{ 
			val fun = [ x | x ]
			val list = $$ListExtensions::map(newArrayList, fun)
			val Iterable<String> iter = list
			fun
		}".resolvesClosuresTo("(String)=>String").withEquivalents("Function1<String, String>")
	}
	
	@Test def void testClosure_20() throws Exception {
		"{ 
			val mapper = [ x | x ]
			$$ListExtensions::map(newArrayList(1), mapper)
		}".resolvesClosuresTo("(Integer)=>Integer")
	}
	
	@Test def void testClosure_21() throws Exception {
		"[|].apply()".resolvesClosuresTo("()=>Object")
	}
	
	@Test def void testClosure_22() throws Exception {
		"[].apply()".resolvesClosuresTo("(Object)=>Object")
	}
	
	@Test def void testClosure_23() throws Exception {
		"$$ListExtensions::map(null as java.util.List<? super String>) [e|e]".resolvesClosuresTo("(Object)=>Object")
	}
	
	@Test def void testClosure_24() throws Exception {
		("{\n" + 
		"  var java.util.List<? super String> list = null;\n" + 
		"  $$ListExtensions::map(list) [e|e]\n" +
		"}").resolvesClosuresTo("(Object)=>Object")
	}
	
	@Test def void testClosure_25() throws Exception {
		"[|'literal']".resolvesClosuresTo("()=>String")
	}
	
	@Test def void testClosure_26() throws Exception {
		"{
			val list = newArrayList('')
			java::util::Collections::sort(list) [ s1, s2 | s1.compareTo(s2) ]
			list
		}".resolvesClosuresTo("(String, String)=>int") // .withEquivalents("Comparator<String>")
	}
	
	@Test def void testEMap_01() throws Exception {
		"{ 
          val eMap = new org.eclipse.emf.common.util.BasicEMap<Integer, String>()
		  eMap.map[ getKey ].head
         }".resolvesClosuresTo("(Entry<Integer, String>)=>Integer")
	}
	
	@Test def void testEMap_02() throws Exception {
		"{ 
          val eMap = new org.eclipse.emf.common.util.BasicEMap<Integer, String>()
		  eMap.map[ getValue ].head
         }".resolvesClosuresTo("(Entry<Integer, String>)=>String")
	}
	
	@Test def void testEMap_03() throws Exception {
		"{ 
          val eMap = new org.eclipse.emf.common.util.BasicEMap<Integer, String>()
		  eMap.map[ it ].head
         }".resolvesClosuresTo("(Entry<Integer, String>)=>Entry<Integer, String>")
	}
	
	@Test def void testMemberFeatureCall_01() throws Exception {
		"(1..20).map[ toString.length ].reduce[ i1,  i2 | i1 + i2 ]".resolvesClosuresTo(
			"(Integer)=>int", "(Integer, Integer)=>int")
	}
	
	@Test def void testFeatureCall_01() throws Exception {
		"newArrayList('').map(s|s)".resolvesClosuresTo("(String)=>String")
	}
	
	@Test def void testFeatureCall_02() throws Exception {
		"newArrayList('').map [it|it]".resolvesClosuresTo("(String)=>String")
	}
	
	@Test def void testFeatureCall_03() throws Exception {
		"newArrayList('').map [it]".resolvesClosuresTo("(String)=>String")
	}
	
	@Test def void testFeatureCall_04() throws Exception {
		"(null as Iterable<String>).map(s|s)".resolvesClosuresTo("(String)=>String")
	}
	
	@Test def void testFeatureCall_05() throws Exception {
		"$$ListExtensions::map(newArrayList('')) [s|s]".resolvesClosuresTo("(String)=>String")
	}
	
	@Test def void testFeatureCall_06() throws Exception {
		"newArrayList('').map(s|s).head".resolvesClosuresTo("(String)=>String")
	}
	
	@Test def void testFeatureCall_07() throws Exception {
		"newArrayList('').map(s|s.toString).head".resolvesClosuresTo("(String)=>String")
	}
	
	@Test def void testFeatureCall_08() throws Exception {
		"newArrayList('').map(s|1)".resolvesClosuresTo("(String)=>int")
	}
	
	@Test def void testFeatureCall_09() throws Exception {
		"newArrayList('').map(s|1).head".resolvesClosuresTo("(String)=>int")
	}
	
	@Test def void testFeatureCall_10() throws Exception {
		"newArrayList('').map(s|s.length)".resolvesClosuresTo("(String)=>int")
	}
	
	@Test def void testFeatureCall_11() throws Exception {
		"<String>newArrayList.map(s|s.length)".resolvesClosuresTo("(String)=>int")
	}
	
	@Test def void testFeatureCall_12() throws Exception {
		"newArrayList('').map(s|s.length).head".resolvesClosuresTo("(String)=>int")
	}
	
	@Test def void testFeatureCall_13() throws Exception {
		"<String>newArrayList.map(s|s.length).head".resolvesClosuresTo("(String)=>int")
	}
	
	@Test def void testFeatureCall_14() throws Exception {
		"newArrayList('').map(s|s != null)".resolvesClosuresTo("(String)=>boolean")
	}
	
	@Test def void testFeatureCall_15() throws Exception {
		"newArrayList('').map(s|s.length+1)".resolvesClosuresTo("(String)=>int")
	}
	
	@Test def void testFeatureCall_16() throws Exception {
		"newArrayList('').map(s|1).map(i|i+1)".resolvesClosuresTo("(String)=>int", "(Integer)=>int")
	}
	
	@Test def void testFeatureCall_17() throws Exception {
		"newArrayList('').map(s|1).toList()".resolvesClosuresTo("(String)=>int")
	}
	
	@Test def void testFeatureCall_18() throws Exception {
		"newArrayList('').map(s|1).toList().map(i|i)".resolvesClosuresTo("(String)=>int", "(Integer)=>Integer")
	}
	
	@Test def void testFeatureCall_19() throws Exception {
		"newArrayList('').map(s|1).toList().map(i|i+1)".resolvesClosuresTo("(String)=>int", "(Integer)=>int")
	}
	
	@Test def void testFeatureCall_20() throws Exception {
		"{ var it = newArrayList('').map(s|1).toList() it.map(i|i+1) }".resolvesClosuresTo("(String)=>int", "(Integer)=>int")
	}
	
	@Test def void testFeatureCall_21() throws Exception {
		"{ var it = newArrayList('').map(s|1).toList() map(i|i+1) }".resolvesClosuresTo("(String)=>int", "(Integer)=>int")
	}
	
	@Test def void testFeatureCall_22() throws Exception {
		"{ var it = newArrayList('').map(s|1).toList() it }".resolvesClosuresTo("(String)=>int")
	}
	
	@Test def void testFeatureCall_23() throws Exception {
		"{ var java.util.List<? extends Integer> it = null map(i|i+1) }".resolvesClosuresTo("(Integer)=>int")
	}
	
	@Test def void testFeatureCall_24() throws Exception {
		"{ var java.util.List<? extends Integer> it = null map(i|i) }".resolvesClosuresTo("(Integer)=>Integer")
	}
	
	@Test def void testFeatureCall_25() throws Exception {
		"newArrayList(newArrayList('').map(s|1))".resolvesClosuresTo("(String)=>int")
	}
	
	@Test def void testFeatureCall_26() throws Exception {
		"newArrayList(newArrayList('').map(s|1)).map(iterable|iterable.size())".resolvesClosuresTo(
			"(String)=>int", "(List<Integer>)=>int")
	}
	
	@Test def void testFeatureCall_27() throws Exception {
		"newArrayList(newArrayList('').map(s|1)).map(iterable|iterable.size()).map(e|e)".resolvesClosuresTo(
			"(String)=>int", "(List<Integer>)=>int", "(Integer)=>Integer")
	}
	
	@Test def void testFeatureCall_28() throws Exception {
		"newArrayList(newArrayList('').map(s|1).map(e|e)).map(iterable|iterable.size())".resolvesClosuresTo(
			"(String)=>int", "(Integer)=>Integer", "(List<Integer>)=>int")
	}
	@Test def void testFeatureCall_29() throws Exception {
		"newArrayList(newArrayList('').map(s|1).map(e|e)).map(iterable|iterable.size()).head".resolvesClosuresTo(
			"(String)=>int", "(Integer)=>Integer", "(List<Integer>)=>int")
	}
	
	@Test def void testFeatureCall_30() throws Exception {
		"newArrayList(newArrayList('')).map(iterable|iterable.size())".resolvesClosuresTo(
			"(ArrayList<String>)=>int");
	}
	@Test def void testFeatureCall_31() throws Exception {
		"newArrayList(newArrayList('')).map(iterable|iterable.size()).head".resolvesClosuresTo(
			"(ArrayList<String>)=>int");
	}
	
	@Test def void testFeatureCall_32() throws Exception {
		"newArrayList(newArrayList('')).map(iterable|iterable.size()).map(e|e)".resolvesClosuresTo(
			"(ArrayList<String>)=>int", "(Integer)=>Integer");
	}
	@Test def void testFeatureCall_33() throws Exception {
		"newArrayList(newArrayList('')).map(iterable|iterable.size()).map(e|e).head".resolvesClosuresTo(
			"(ArrayList<String>)=>int", "(Integer)=>Integer");
	}
	
	@Test def void testFeatureCall_34() throws Exception {
		"newArrayList('').map(s|1).map(i|1)".resolvesClosuresTo("(String)=>int", "(Integer)=>int")
	}
	@Test def void testFeatureCall_35() throws Exception {
		"newArrayList('').map(s|1).map(i|1).head".resolvesClosuresTo("(String)=>int", "(Integer)=>int")
	}
	
	@Test def void testFeatureCall_36() throws Exception {
		"newArrayList('').map(s|s.length).map(i|i)".resolvesClosuresTo("(String)=>int", "(Integer)=>Integer")
	}
	@Test def void testFeatureCall_37() throws Exception {
		"newArrayList('').map(s|s.length).map(i|i).head".resolvesClosuresTo("(String)=>int", "(Integer)=>Integer")
	}
	
	@Test def void testFeatureCall_38() throws Exception {
		"newArrayList('').map(s|s.length + 1 == 5).map(b|b)".resolvesClosuresTo(
			"(String)=>boolean", "(Boolean)=>Boolean")
	}
	@Test def void testFeatureCall_39() throws Exception {
		"newArrayList('').map(s|s.length + 1 == 5).map(b|b).head".resolvesClosuresTo(
			"(String)=>boolean", "(Boolean)=>Boolean")
	}
	
	@Test def void testFeatureCall_40() throws Exception {
		"newArrayList('').map(s|s.length + 1 == 5).map(b| { 'length'.length b })".resolvesClosuresTo(
			"(String)=>boolean", "(Boolean)=>Boolean")
	}
	@Test def void testFeatureCall_41() throws Exception {
		"newArrayList('').map(s|s.length + 1 == 5).map(b| { 'length'.length b }).head".resolvesClosuresTo(
			"(String)=>boolean", "(Boolean)=>Boolean")
	}
	
	@Test def void testFeatureCall_42() throws Exception {
		"newArrayList('').map(s|s.length + 1 == 5).map(Boolean b|!b)".resolvesClosuresTo(
			"(String)=>boolean", "(Boolean)=>boolean")
	}
	@Test def void testFeatureCall_43() throws Exception {
		"newArrayList('').map(s|s.length + 1 == 5).map(Boolean b|!b).head".resolvesClosuresTo(
			"(String)=>boolean", "(Boolean)=>boolean")
	}
	
	@Test def void testFeatureCall_44() throws Exception {
		"newArrayList('').map(s|s.length + 1 == 5).map(b| !!b )".resolvesClosuresTo(
			"(String)=>boolean", "(Boolean)=>boolean")
	}
	@Test def void testFeatureCall_45() throws Exception {
		"newArrayList('').map(s|s.length + 1 == 5).map(b| !!b ).head".resolvesClosuresTo(
			"(String)=>boolean", "(Boolean)=>boolean")
	}
	
	@Test def void testFeatureCall_46() throws Exception {
		"newArrayList('').map(s|s.length + 1 == 5).map(b| { !b } )".resolvesClosuresTo(
			"(String)=>boolean", "(Boolean)=>boolean")
	}
	@Test def void testFeatureCall_47() throws Exception {
		"newArrayList('').map(s|s.length + 1 == 5).map(b| { !b } ).head".resolvesClosuresTo(
			"(String)=>boolean", "(Boolean)=>boolean")
	}
	
	@Test def void testFeatureCall_48() throws Exception {
		"newArrayList('').map(s|s.length + 1 == 5).map(b| { b.operator_not } )".resolvesClosuresTo(
			"(String)=>boolean", "(Boolean)=>boolean")
	}
	@Test def void testFeatureCall_49() throws Exception {
		"newArrayList('').map(s|s.length + 1 == 5).map(b| { b.operator_not } ).head".resolvesClosuresTo(
			"(String)=>boolean", "(Boolean)=>boolean")
	}

	@Test def void testFeatureCall_50() throws Exception {
		("newArrayList('').map(s|" +
				"$$ObjectExtensions::operator_equals(" +
				"	$$IntegerExtensions::operator_plus(s.length,1), 5)" +
				").map(b| $$BooleanExtensions::operator_not(b) )").resolvesClosuresTo(
			"(String)=>boolean", "(Boolean)=>boolean")
	}
	@Test def void testFeatureCall_51() throws Exception {
		("newArrayList('').map(s|" +
				"$$ObjectExtensions::operator_equals(" +
				"	$$IntegerExtensions::operator_plus(s.length,1), 5)" +
				").map(b| $$BooleanExtensions::operator_not(b) ).head").resolvesClosuresTo(
			"(String)=>boolean", "(Boolean)=>boolean")
	}
	
	@Test def void testFeatureCall_52() throws Exception {
		"newArrayList('').map(s|s.length + 1 * 5).map(b| b / 5 )".resolvesClosuresTo(
			"(String)=>int", "(Integer)=>int")
	}
	@Test def void testFeatureCall_53() throws Exception {
		"newArrayList('').map(s|s.length + 1 * 5).map(b| b / 5 ).head".resolvesClosuresTo(
			"(String)=>int", "(Integer)=>int")
	}
	
	@Test def void testFeatureCall_54() throws Exception {
		"newArrayList('').map[ length + 1 * 5 ].map [ it / 5 ).head".resolvesClosuresTo(
			"(String)=>int", "(Integer)=>int")
	}
	
	@Ignore("Too slow")
	@Test def void testFeatureCall_55() throws Exception {
		"newArrayList('').map[ length + 1 * 5 - length + 1 * 5 ].map [ it / 5 + 1 / it ).head".resolvesClosuresTo(
			"(String)=>int", "(Integer)=>int")
	}
	
	@Test def void testFeatureCall_56() throws Exception {
		"{ val list = newArrayList(if (false) new Double('-20') else new Integer('20')).map(v|v.intValue)
           val Object o = list.head 
           list
        }".resolvesClosuresTo("(Number & Comparable<?>)=>int");
	}
	
	@Test def void testFeatureCall_57() throws Exception {
		"{ val list = newArrayList(if (false) new Double('-20') else new Integer('20')).map(v|v.intValue)
           val Object o = list.head 
           list.head
        }".resolvesClosuresTo("(Number & Comparable<?>)=>int");
	}
	
	@Test def void testFeatureCall_58() throws Exception {
		"{ val list = $$ListExtensions::map(newArrayList(if (false) new Double('-20') else new Integer('20'))) [ v|v.intValue ]
           val Object o = list.head 
           list
        }".resolvesClosuresTo("(Number & Comparable<?>)=>int");
	}
	
	@Test def void testFeatureCall_59() throws Exception {
		"{ val list = $$ListExtensions::map(newArrayList(null as Integer)) [ v|v.intValue ]
           val Object o = list.head 
           list
        }".resolvesClosuresTo("(Integer)=>int");
	}

	@Test def void testFeatureCall_60() throws Exception {
		"{ val list = newArrayList(null as Integer).map [ v|v.intValue ]
           val Object o = list.head 
           list
        }".resolvesClosuresTo("(Integer)=>int");
	}
	
	@Test def void testFeatureCall_61() throws Exception {
		"{ val list = newArrayList(null as Integer).map [ v|v.intValue ]
           val Object o = list.head 
           list.findFirst [ intValue == 0 ]
        }".resolvesClosuresTo("(Integer)=>int", "(Integer)=>boolean");
	}
	
	@Test def void testFeatureCall_62() throws Exception {
		"{
			val list = newArrayList
			list.forEach[String s | s]
			list
		}".resolvesClosuresTo("(String)=>void")
	}
	
	@Test def void testFeatureCall_63() throws Exception {
		"{
			val list = newArrayList
			list.findFirst[String s | true]
			list
		}".resolvesClosuresTo("(String)=>boolean")
	}
	
	@Test def void testFeatureCall_64() throws Exception {
		"newArrayList.map[String s | s.substring(1,1) ]".resolvesClosuresTo("(String)=>String")
	}

	@Test def void testFeatureCall_65() throws Exception {
		"newArrayList.map[ s | s.toString ]".resolvesClosuresTo("(Object)=>String")
	}
	
	@Test def void testFeatureCall_66() throws Exception {
		"{
			val list = newArrayList
			list.forEach[ s | s.toString ]
			list
		}".resolvesClosuresTo("(Object)=>void")
	}
	
	@Test def void testFeatureCall_67() throws Exception {
		"{ val list = newArrayList(new Double('-20'), new Integer('20')).map(v|v.intValue)
           val Object o = list.head 
           list
        }".resolvesClosuresTo("(Number & Comparable<?>)=>int");
	}
	
	@Test def void testFeatureCall_68() throws Exception {
		"{ val list = newArrayList(new Double('-20'), new Integer('20')).map(v|v.intValue)
           val Object o = list.head 
           list.head
        }".resolvesClosuresTo("(Number & Comparable<?>)=>int");
	}
	
	@Test def void testFeatureCall_69() throws Exception {
		"{ val list = $$ListExtensions::map(newArrayList(new Double('-20'), new Integer('20'))) [ v|v.intValue ]
           val Object o = list.head 
           list
        }".resolvesClosuresTo("(Number & Comparable<?>)=>int");
	}
	
	@Test def void testFeatureCall_Bug342134_00() throws Exception {
		"(null as java.util.List<String>).map(e|newArrayList(e)).flatten".resolvesClosuresTo(
			"(String)=>ArrayList<String>")
	}
	
	@Test def void testFeatureCall_Bug342134_01() throws Exception {
		"(null as java.util.List<String>).map(e|newArrayList(e)).flatten.head".resolvesClosuresTo(
			"(String)=>ArrayList<String>")
	}
	
	@Test def void testFeatureCall_Bug342134_02() throws Exception {
		"newArrayList('').map(e|newArrayList(e)).flatten".resolvesClosuresTo(
			"(String)=>ArrayList<String>")
	}
	
	@Test def void testFeatureCall_Bug342134_03() throws Exception {
		"newArrayList('').map(e|newArrayList(e)).flatten.head".resolvesClosuresTo(
			"(String)=>ArrayList<String>")
	}
	
	@Test def void testFeatureCall_Bug342134_04() throws Exception {
		"newArrayList('').map(e|newArrayList(e))".resolvesClosuresTo("(String)=>ArrayList<String>")
	}
	
	@Test def void testFeatureCall_Bug342134_05() throws Exception {
		"newArrayList('').map(e|newArrayList(e)).head".resolvesClosuresTo("(String)=>ArrayList<String>")
	}
	
	@Test def void testFeatureCall_Bug342134_06() throws Exception {
		"<String>newArrayList.map(e|newArrayList(e)).flatten".resolvesClosuresTo("(String)=>ArrayList<String>")
	}
	
	@Test def void testFeatureCall_Bug342134_07() throws Exception {
		"newArrayList('').map(e|<String>newArrayList(e)).flatten".resolvesClosuresTo("(String)=>ArrayList<String>")
	}
	
	@Test def void testFeatureCall_Bug342134_08() throws Exception {
		"newArrayList.map(String e|<String>newArrayList(e)).flatten".resolvesClosuresTo("(String)=>ArrayList<String>")
	}
	
	@Test def void testDeferredTypeArgumentResolution_01() throws Exception {
		"{
			val list = newArrayList
			val fun = [String s| s]
			list.map(fun)
			list
		}".resolvesClosuresTo("(String)=>String")
	}
	
	@Test def void testDeferredTypeArgumentResolution_02() throws Exception {
		"{
			val list = new java.util.ArrayList
			list.map[String s| s]
			list
		}".resolvesClosuresTo("(String)=>String")
	}
	
	@Test def void testDeferredTypeArgumentResolution_03() throws Exception {
		"{
			val list = newArrayList
			list.map[String s| s]
			list
		}".resolvesClosuresTo("(String)=>String")
	}
	
	@Test def void testDeferredTypeArgumentResolution_04() throws Exception {
		"{
			val list = newArrayList
			$$IterableExtensions::map(list, [String s| s])
			list
		}".resolvesClosuresTo("(String)=>String")
	}
	
	@Test def void testDeferredTypeArgumentResolution_05() throws Exception {
		"{
			val list = newArrayList
			val fun = [String s| s]
			$$IterableExtensions::map(list, fun)
			list
		}".resolvesClosuresTo("(String)=>String")
	}
	
	@Test def void testDeferredTypeArgumentResolution_06() throws Exception {
		"{
			val list = new java.util.ArrayList
			list.map(println([String s| println(s)]))
			list
		}".resolvesClosuresTo("(String)=>String")
	}
	
}