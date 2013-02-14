/*
 * Copyright (c) 2013, the Dart project authors.
 * 
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 * 
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package com.google.dart.engine.element.visitor;

import com.google.dart.engine.element.ClassElement;
import com.google.dart.engine.element.CompilationUnitElement;
import com.google.dart.engine.element.ConstructorElement;
import com.google.dart.engine.element.Element;
import com.google.dart.engine.element.ElementVisitor;
import com.google.dart.engine.element.ExecutableElement;
import com.google.dart.engine.element.ExportElement;
import com.google.dart.engine.element.FieldElement;
import com.google.dart.engine.element.FunctionElement;
import com.google.dart.engine.element.HtmlElement;
import com.google.dart.engine.element.ImportElement;
import com.google.dart.engine.element.LabelElement;
import com.google.dart.engine.element.LibraryElement;
import com.google.dart.engine.element.MethodElement;
import com.google.dart.engine.element.MultiplyDefinedElement;
import com.google.dart.engine.element.ParameterElement;
import com.google.dart.engine.element.PrefixElement;
import com.google.dart.engine.element.PropertyAccessorElement;
import com.google.dart.engine.element.TypeAliasElement;
import com.google.dart.engine.element.TypeVariableElement;
import com.google.dart.engine.element.VariableElement;

/**
 * Instances of the class {@code GeneralizingElementVisitor} implement an element visitor that will
 * recursively visit all of the elements in an element model (like instances of the class
 * {@link RecursiveElementVisitor}). In addition, when an element of a specific type is visited not
 * only will the visit method for that specific type of element be invoked, but additional methods
 * for the superclasses of that element will also be invoked. For example, using an instance of this
 * class to visit a {@link FieldElement} will cause the method
 * {@link #visitFieldElement(FieldElement)} to be invoked but will also cause the methods
 * {@link #visitVariableElement(VariableElement)} and {@link #visitElement(Element)} to be
 * subsequently invoked. This allows visitors to be written that visit all variables without needing
 * to override the visit method for each of the specific subclasses of {@link VariableElement}.
 * <p>
 * Subclasses that override a visit method must either invoke the overridden visit method or
 * explicitly invoke the more general visit method. Failure to do so will cause the visit methods
 * for superclasses of the element to not be invoked and will cause the children of the visited node
 * to not be visited.
 */
public class GeneralizingElementVisitor<R> implements ElementVisitor<R> {
  @Override
  public R visitClassElement(ClassElement element) {
    return visitElement(element);
  }

  @Override
  public R visitCompilationUnitElement(CompilationUnitElement element) {
    return visitElement(element);
  }

  @Override
  public R visitConstructorElement(ConstructorElement element) {
    return visitExecutableElement(element);
  }

  public R visitElement(Element element) {
    element.visitChildren(this);
    return null;
  }

  public R visitExecutableElement(ExecutableElement element) {
    return visitElement(element);
  }

  @Override
  public R visitExportElement(ExportElement element) {
    return visitElement(element);
  }

  @Override
  public R visitFieldElement(FieldElement element) {
    return visitVariableElement(element);
  }

  @Override
  public R visitFunctionElement(FunctionElement element) {
    return visitExecutableElement(element);
  }

  @Override
  public R visitHtmlElement(HtmlElement element) {
    return visitElement(element);
  }

  @Override
  public R visitImportElement(ImportElement element) {
    return visitElement(element);
  }

  @Override
  public R visitLabelElement(LabelElement element) {
    return visitElement(element);
  }

  @Override
  public R visitLibraryElement(LibraryElement element) {
    return visitElement(element);
  }

  @Override
  public R visitMethodElement(MethodElement element) {
    return visitExecutableElement(element);
  }

  @Override
  public R visitMultiplyDefinedElement(MultiplyDefinedElement element) {
    return visitElement(element);
  }

  @Override
  public R visitParameterElement(ParameterElement element) {
    return visitVariableElement(element);
  }

  @Override
  public R visitPrefixElement(PrefixElement element) {
    return visitElement(element);
  }

  @Override
  public R visitPropertyAccessorElement(PropertyAccessorElement element) {
    return visitExecutableElement(element);
  }

  @Override
  public R visitTypeAliasElement(TypeAliasElement element) {
    return visitElement(element);
  }

  @Override
  public R visitTypeVariableElement(TypeVariableElement element) {
    return visitElement(element);
  }

  @Override
  public R visitVariableElement(VariableElement element) {
    return visitElement(element);
  }
}