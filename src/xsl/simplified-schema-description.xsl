<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:html="http://www.w3.org/1999/xhtml" 
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    
    version="3.0" 
    exclude-result-prefixes="xsd html">
  
  <xsl:output 
      method="xml" 
      encoding="UTF-8"
      standalone="yes"
      version="1.0"
      indent="yes"/>
  
  <!--..... Schema Process .................-->
  <xsl:template match="/xsd:schema">
    <xsl:element name="{./*[1]/@name}" namespace="" >
      <xsl:apply-templates select="xsd:element[1]/*"/>
    </xsl:element>
  </xsl:template>

  <!-- Element : Structure Element ........ -->
  <xsl:template
      match="xsd:element[not(@ref) and not(@type)]" >
    <item>
      <xsl:comment>Debug:  Element <xsl:value-of select="local-name()" /> <xsl:value-of select="@name" /> - <xsl:value-of select="@ref" /> </xsl:comment>
      <xsl:if test="@*" >
	<xsl:apply-templates select="@*[not(name()='id')]" />
	<xsl:if test="(boolean(@*:minOccurs) or boolean(@*:maxOccurs))" >
	  <xsl:call-template name="cardinalidad" >
	    <xsl:with-param name="min" select="@*:minOccurs" />
	    <xsl:with-param name="max" select="@*:maxOccurs" />
	  </xsl:call-template>
	</xsl:if>
      </xsl:if>


      <xsl:apply-templates select="element()|xsd:complexType|xsd:simpleType|xsd:complexContent" />
    </item>
  </xsl:template>

  <!-- Element : Reference to element ........ -->
  <xsl:template
      match="xsd:element[boolean(@ref)]" >
    <element>

      <name><xsl:value-of select="@ref" /></name>
      <xsl:if test="(boolean(@*:minOccurs) or boolean(@*:maxOccurs))" >
	<xsl:call-template name="cardinalidad" >
	  <xsl:with-param name="min" select="@*:minOccurs" />
	  <xsl:with-param name="max" select="@*:maxOccurs" />
	</xsl:call-template>
      </xsl:if>
      <xsl:call-template name="referenced-element" >
	<xsl:with-param name="ref" select="string(@ref)" />
      </xsl:call-template>

    </element>
  </xsl:template>

  <!-- ........ Element : Rest of elements ........ -->
  <xsl:template
      match="xsd:element" >
    <element>
      <xsl:if test="@name" >
	<name><xsl:value-of select="@name" /></name>
      </xsl:if>
      <xsl:if test="(boolean(@*:minOccurs) or boolean(@*:maxOccurs))" >
	<xsl:call-template name="cardinalidad" >
	  <xsl:with-param name="min" select="@*:minOccurs" />
	  <xsl:with-param name="max" select="@*:maxOccurs" />
	</xsl:call-template>
      </xsl:if>
      <xsl:if test="@type" >
	<xsl:if test="contains(@type, 'xsd:' )" >
	  <type><xsl:value-of select="@type" /></type>
	</xsl:if>
	<xsl:if test="not(contains(@type, 'xsd:'))" >
	  <xsl:apply-templates select="@type" />
	</xsl:if>
      </xsl:if>
    </element>
  </xsl:template>

  <!-- Look for elements by reference -->
  <xsl:template name="referenced-element" >
    <xsl:param name="ref" />

    <xsl:if test="not(/*/xsd:element[@name=$ref])" >
      <xsl:comment> Warning : element <xsl:value-of select="@ref" /> </xsl:comment>
    </xsl:if>
    <xsl:for-each select="/*/xsd:element[@name=$ref]" >

      <xsl:if test="@type" >
	<xsl:variable name="tipo" select="@type" />
	<xsl:if test="contains(@type, 'xsd:' )" >
	  <type><xsl:value-of select="@type" /></type>
	</xsl:if>
	<xsl:if test="not(contains(@type, 'xsd:' ))" >
	  <xsl:comment> Debug : looking for type <xsl:value-of select="@ref" /> - <xsl:value-of select="@type" /> </xsl:comment>
	  <xsl:apply-templates
	      select="/*/xsd:simpleType[@name=$tipo]|/*/xsd:complexType[@name=$tipo]" />
	</xsl:if>
      </xsl:if>

      <xsl:apply-templates select="element()|xsd:complexType|xsd:simpleType|xsd:complexContent" />
      
      
    </xsl:for-each>
  </xsl:template>


  <xsl:template
      match="xsd:group|xsd:attributeGroup|xsd:sequence" >

      <xsl:comment>Debug:  Group-Sequence <xsl:value-of select="local-name()" /> <xsl:value-of select="@name" /> - <xsl:value-of select="@ref" /> </xsl:comment>
      <xsl:apply-templates select="element()" />
      <xsl:for-each select="xsd:group|xsd:attributeGroup|xsd:sequence/xsd:group|xsd:sequence/xsd:attributeGroup" >
	<xsl:if test="@ref" >
	  <xsl:variable name="directReference" select="substring-after(string(@ref), ':' )" />
	  <xsl:apply-templates select="//*[@name=$directReference]" />
	</xsl:if>
	<xsl:if test="@type" >
	  <xsl:variable name="directType" select="substring-after(string(@type), ':' )" />
	  <xsl:apply-templates select="//*[@name=$directType]" />
	</xsl:if>
      </xsl:for-each>
</xsl:template>

<xsl:template match="xsd:complexType|xsd:simpleType|xsd:choice|xsd:complexContent" >
  
  <xsl:comment>  ......Debug.. <xsl:value-of select="../name" /> <xsl:value-of select="local-name()" /> ........ </xsl:comment>
  
  <xsl:apply-templates/>

</xsl:template>

	
  <!-- ............. Attributes .................... -->
  <xsl:template match="xsd:attribute[not(@ref)]" >
    <xsl:variable name="reference" select="substring(@type, 9)" />
    <xsl:variable name="referenced" select="//xsd:simpleType[(@*:name=$reference and not(@ref))]" />
    <attribute>
      <attribute-name><xsl:value-of select="string(@name)" /></attribute-name>
      <xsl:if test="@use='optional'" ><cardinality><optional/></cardinality></xsl:if>
      <xsl:if test="@use='required'" ><cardinality><required/></cardinality></xsl:if>
      <xsl:apply-templates select="$referenced" />
      <xsl:apply-templates  />
    </attribute>
  </xsl:template>

  <!-- ................. Attributo ref .............. -->
  <xsl:template match="xsd:attribute[@ref]" >
    <xsl:variable name="ref" select="@ref" />
    <attribute>
      <attribute-name><xsl:value-of select="$ref" /></attribute-name>
      <xsl:if test="@use='optional'" ><cardinality><optional/></cardinality></xsl:if>
      <xsl:if test="@use='required'" ><cardinality><required/></cardinality></xsl:if>
      <xsl:call-template name="attribute-refs">
	<xsl:with-param name="attribute"
			select="//xsd:attribute[@name=$ref]" />	
      </xsl:call-template>
    </attribute>
  </xsl:template>

  <xsl:template name="attribute-refs" >
    <xsl:param name="attribute"  />
    <xsl:if test="$attribute/@*:type" >
      <xsl:comment  >debug : buscando tipo
	<xsl:value-of select="$attribute/@*:type" >
	</xsl:value-of>
      </xsl:comment>
      <xsl:call-template name="tipo" >
	<xsl:with-param name="tipo" select="$attribute/@*:type" />
      </xsl:call-template>
    </xsl:if>

  </xsl:template>


  <!--
    <xsd:complexContent>
      <xsd:extension base="NameDescriptionType">
  -->


  <xsl:template match="xsd:extension[@base]" >
    <xsl:comment> ... Debug: Extension ... <xsl:value-of select="@base" ></xsl:value-of>
    </xsl:comment>
    
    <xsl:variable name="tipo" select="@base" />
    <xsl:apply-templates
	select="/*/xsd:simpleType[@name=$tipo]|/*/xsd:complexType[@name=$tipo]" />

    <xsl:apply-templates />

    
  </xsl:template>

  
  <xsl:template name="tipo" >
    
    <xsl:param name="tipo"  />
    <xsl:comment  >debug : recibido tipo
      <xsl:value-of select="$tipo" >
    </xsl:value-of>
    </xsl:comment>
    <xsl:if test="contains($tipo, 'xsd:' )" >
      <type><xsl:value-of select="$tipo" /></type>
    </xsl:if>
    <xsl:if test="not(contains($tipo, 'xsd:' ))" >
      <xsl:comment> Debug : looking for type <xsl:value-of select="@ref" /> - <xsl:value-of select="$tipo" /> </xsl:comment>
      <xsl:apply-templates
	  select="/*/xsd:simpleType[@name=$tipo]|/*/xsd:complexType[@name=$tipo]" />
    </xsl:if>
  </xsl:template>

  
  <xsl:template name="cardinalidad" >
    <xsl:param name="min" />
    <xsl:param name="max" /><cardinality><xsl:choose>
    <xsl:when test="number($min) = 0"><optional/></xsl:when>
    <xsl:when test="not($min)"><mandatory/></xsl:when>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="not($max)"><unique/></xsl:when>
    <xsl:when test="number($max) != 1"><multiple max="{$max}" /></xsl:when>
    <xsl:when test="number($max) = 1"><unique/></xsl:when>
    <xsl:otherwise><max value="{$max}" /></xsl:otherwise>
  </xsl:choose>
</cardinality>
  </xsl:template>

  <xsl:template match="xsd:restriction[@base='xsd:string']" >
    <type>xsd:string</type>
    <!-- TODO
	 <xsd:length value="0"/>
    -->
    <allowed-values>
      <xsl:for-each select="*:enumeration" >
	<value><xsl:value-of select="string(@value)" /></value>
      </xsl:for-each>
    </allowed-values>
  </xsl:template>

  <xsl:template match="xsd:union" >
    <xsl:for-each select="tokenize(@memberTypes,' ')[1]">
      <type>
        <xsl:value-of select="."/>
      </type>
    </xsl:for-each>
  </xsl:template>

  <!-- ............ Attributes ..................... -->

  <xsl:template match="@type" >
    <xsl:comment>Debug: @type <xsl:value-of select="@name" /> -  <xsl:value-of select="." /> </xsl:comment>
    <declared-type><xsl:value-of select="string(.)" /></declared-type>
    <xsl:variable name="typedreference" select="substring-after(string(.), ':')" />
    <xsl:variable name="simpleTypedreference" select="string(.)" />
    
    <xsl:apply-templates select="//*:complexType[@name=$typedreference]" />
    <xsl:apply-templates select="//*:simpleType[@name=$typedreference]" />
    <xsl:apply-templates select="//*:complexType[@name=$simpleTypedreference]" />
    <xsl:apply-templates select="//*:simpleType[@name=$simpleTypedreference]" />
    
  </xsl:template>
  
  <xsl:template match="@ref" >
    <ref><xsl:value-of select="string(.)" /></ref>
    <xsl:variable name="typedreference" select="string(.)" />
    <xsl:if test="boolean(@*:minOccurs) or boolean(@*:maxOccurs)" >
      <xsl:call-template name="cardinalidad" >
	<xsl:with-param name="min" select="string(@*:minOccurs)" />
	<xsl:with-param name="max" select="string(@*:maxOccurs)" />
      </xsl:call-template>
    </xsl:if>
    <xsl:apply-templates select="//*[@name=$typedreference]" />
  </xsl:template>

  <xsl:template match="@*:name" >
    <name><xsl:value-of select="string(.)" /></name>
  </xsl:template>
  
  <!-- ............ Documentaion ..................... -->
  <xsl:template match="xsd:annotation" >
    <xsl:comment>
      <xsl:value-of select="xsd:documentation/text()" />
    </xsl:comment>
  </xsl:template>

  <!-- ............ Text ..................... -->
  <xsl:template match="text()" ></xsl:template>
  
</xsl:stylesheet>
