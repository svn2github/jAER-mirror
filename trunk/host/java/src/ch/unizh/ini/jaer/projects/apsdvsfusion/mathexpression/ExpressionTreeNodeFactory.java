/**
 * 
 */
package ch.unizh.ini.jaer.projects.apsdvsfusion.mathexpression;

import java.util.HashMap;
import java.util.LinkedList;

import ch.unizh.ini.jaer.projects.apsdvsfusion.mathexpression.BinaryOperationETNode.SimpleBinaryOperationCreator;
import ch.unizh.ini.jaer.projects.apsdvsfusion.mathexpression.FunctionETNode.SimpleFunctionETNodeCreator;

/**
 * @author Dennis
 *
 */
public class ExpressionTreeNodeFactory {

	static HashMap<String, BinaryOperationETNodeCreator> binaryOperationMap = new HashMap<String, BinaryOperationETNodeCreator>();
	static HashMap<String, FunctionETNodeCreator> functionMap = new HashMap<String, FunctionETNodeCreator>();
	static HashMap<String, ConstantETNode> constantsMap = new HashMap<String, ConstantETNode>();
	
	static {
		ExpressionTreeNodeFactory.addOperation(new SimpleBinaryOperationCreator("+", 50) {
			@Override public double compute(double left, double right) { 	return left + right;	}	});
		ExpressionTreeNodeFactory.addOperation(new SimpleBinaryOperationCreator("-", 50) {
			@Override public double compute(double left, double right) { 	return left - right;	}	});
		ExpressionTreeNodeFactory.addOperation(new SimpleBinaryOperationCreator("*",100) {
			@Override public double compute(double left, double right) { 	return left * right;	}	});
		ExpressionTreeNodeFactory.addOperation(new SimpleBinaryOperationCreator("/",100) {
			@Override public double compute(double left, double right) { 	return left = right;	}	});
		ExpressionTreeNodeFactory.addOperation(new SimpleBinaryOperationCreator("^",100) {
			@Override public double compute(double left, double right) { 	return Math.pow(left, right);	}	});
		ExpressionTreeNodeFactory.addOperation(new SimpleBinaryOperationCreator("=",100) {
			@Override public double compute(double left, double right) { 	if (left == right) return 1.0; else return 0.0;	}	});

		ExpressionTreeNodeFactory.addFunction(new SimpleFunctionETNodeCreator("pow",200, 2) {
			@Override protected double compute(double[] arguments) { return Math.pow(arguments[0], arguments[1]);	}	});
		ExpressionTreeNodeFactory.addFunction(new SimpleFunctionETNodeCreator("min",200, 2) {
			@Override protected double compute(double[] arguments) { return Math.min(arguments[0], arguments[1]);	}	});
		ExpressionTreeNodeFactory.addFunction(new SimpleFunctionETNodeCreator("max",200, 2) {
			@Override protected double compute(double[] arguments) { return Math.max(arguments[0], arguments[1]);	}	});
		ExpressionTreeNodeFactory.addFunction(new SimpleFunctionETNodeCreator("exp",200, 1) {
			@Override protected double compute(double[] arguments) { return Math.exp(arguments[0]);	}	});
		ExpressionTreeNodeFactory.addFunction(new SimpleFunctionETNodeCreator("cos",200, 1) {
			@Override protected double compute(double[] arguments) { return Math.cos(arguments[0]);	}	});
		ExpressionTreeNodeFactory.addFunction(new SimpleFunctionETNodeCreator("sin",200, 1) {
			@Override protected double compute(double[] arguments) { return Math.sin(arguments[0]);	}	});
		ExpressionTreeNodeFactory.addFunction(new SimpleFunctionETNodeCreator("acos",200, 1) {
			@Override protected double compute(double[] arguments) { return Math.acos(arguments[0]);	}	});
		ExpressionTreeNodeFactory.addFunction(new SimpleFunctionETNodeCreator("asin",200, 1) {
			@Override protected double compute(double[] arguments) { return Math.asin(arguments[0]);	}	});
		ExpressionTreeNodeFactory.addFunction(new SimpleFunctionETNodeCreator("tan",200, 1) {
			@Override protected double compute(double[] arguments) { return Math.tan(arguments[0]);	}	});

		
		ExpressionTreeNodeFactory.addConstant("PI", Math.PI);
		ExpressionTreeNodeFactory.addConstant("E", Math.E);
	}
	
	
	static boolean existsOperation(String s) {
		return binaryOperationMap.containsKey(s);
	}

	static boolean existsFunction(String s) {
		return functionMap.containsKey(s);
	}
	
	static int getOperationPriority(String symbol) {
		if (!binaryOperationMap.containsKey(symbol)) return -1;
		else return binaryOperationMap.get(symbol).priority();
	}
	
	// "expensive" operation... should be replaced by a better lookup scheme, but for 10-20 operations, this really shouldn't matter...
	static int matchingOperations(String s) {
		int ret = 0;
		for (String a : binaryOperationMap.keySet()) {
			if (a.startsWith(s))
				ret++;
		}
		return ret;
	}
	
	static FunctionETNode createFunctionNode(String symbol, ExpressionTreeNode[] arguments) throws IllegalExpressionException {
		FunctionETNodeCreator c = functionMap.get(symbol);
		if (c != null)
			return c.createExpressionTreeNode(arguments);
		throw new IllegalExpressionException("Function "+symbol+" is unknown!");
	}

	static BinaryOperationETNode createBinaryOperationNode(String symbol, ExpressionTreeNode[] arguments) throws IllegalExpressionException {
		BinaryOperationETNodeCreator c = binaryOperationMap.get(symbol);
		if (c != null)
			return c.createExpressionTreeNode(arguments);
		throw new IllegalExpressionException("Function "+symbol+" is unknown!");
	}

	static void addOperation(BinaryOperationETNodeCreator creator) {
		binaryOperationMap.put(creator.symbol(), creator);
	}
	static void addFunction(FunctionETNodeCreator creator) {
		functionMap.put(creator.symbol(), creator);
	}
	
	static void addConstant(String symbol, double value) {
		constantsMap.put(symbol,new ConstantETNode(value));
	}
	static boolean existsConstant(String symbol) {
		return constantsMap.containsKey(symbol);
	}
	static ConstantETNode getConstant(String symbol) throws IllegalExpressionException {
		if (constantsMap.containsKey(symbol)) 
			return constantsMap.get(symbol);
		else
			throw new IllegalExpressionException(symbol+" is not a constant!");
	}
	
	/**
	 * 
	 */
	public ExpressionTreeNodeFactory() {
		// TODO Auto-generated constructor stub
	}

	static int getFunctionArgumentCount(
			String token) {
		if (functionMap.containsKey(token))
			return functionMap.get(token).getNumberOfArguments();
		else return -1;
	}

}
