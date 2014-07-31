<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:template match="emptyfont">
    <xsl:element name="font">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="inlinefont">
    <xsl:if test="node()">
      <xsl:variable name="csscolor"><xsl:call-template name="color"/></xsl:variable>
      <xsl:variable name="csssize"><xsl:call-template name="size"/></xsl:variable>
      <xsl:variable name="cssface"><xsl:call-template name="face"/></xsl:variable>
      <xsl:variable name="symbol"><xsl:call-template name="has-symbol"/></xsl:variable>
      <xsl:choose>
        <xsl:when test="$csscolor = '' and $csssize = '' and $cssface = '' and $symbol = 'yes'">
          <xsl:call-template name="symbol-content"/>
        </xsl:when>
        <xsl:otherwise>
          <span style="{$csscolor}{$csssize}{$cssface}">
            <xsl:choose>
              <xsl:when test="$symbol = 'yes'">
                <xsl:call-template name="symbol-content"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="node()"/>
              </xsl:otherwise>
            </xsl:choose>
          </span>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="blockfont">
    <xsl:if test="node()">
      <xsl:variable name="csscolor"><xsl:call-template name="color"/></xsl:variable>
      <xsl:variable name="csssize"><xsl:call-template name="size"/></xsl:variable>
      <xsl:variable name="cssface"><xsl:call-template name="face"/></xsl:variable>
      <xsl:variable name="symbol"><xsl:call-template name="has-symbol"/></xsl:variable>
      <div style="{$csscolor}{$csssize}{$cssface}">
        <xsl:choose>
          <xsl:when test="$symbol = 'yes'"> <!-- we will not do that test recursively -->
            <xsl:call-template name="symbol-content"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="node()"/>
          </xsl:otherwise>
        </xsl:choose>
      </div>
    </xsl:if>
  </xsl:template>

  <xsl:template name="color">
    <xsl:if test="@color|@COLOR">
      <xsl:text>color:</xsl:text>
      <xsl:for-each select="@color|@COLOR">
        <xsl:choose>
          <xsl:when test="starts-with(., 'x')">
            <xsl:value-of select="concat('#', substring(., 1))"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="."/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <xsl:text>;</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="size">
  <!-- for now assuming basefont 3 -->
    <xsl:if test="@size|@SIZE">
      <xsl:text>font-size:</xsl:text>
        <xsl:for-each select="@size|@SIZE">
          <xsl:choose>
            <xsl:when test=". = '1'">x-small</xsl:when>
            <xsl:when test=". = '2'">small</xsl:when>
            <xsl:when test=". = '3'">medium</xsl:when>
            <xsl:when test=". = '4'">large</xsl:when>
            <xsl:when test=". = '5'">x-large</xsl:when>
            <xsl:when test=". = '6'">xx-large</xsl:when>
            <xsl:when test=". = '7'">300%</xsl:when>
            <xsl:when test=". = '-1'">small</xsl:when>
            <xsl:when test=". = '-2'">x-small</xsl:when>
            <xsl:when test=". = '+1'">large</xsl:when>
            <xsl:when test=". = '+2'">x-large</xsl:when>
            <xsl:when test=". = '+3'">xx-large</xsl:when>
            <xsl:when test=". = '+4'">300%</xsl:when>
            <xsl:otherwise>medium</xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      <xsl:text>;</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="face">
    <xsl:variable name="symbol"><xsl:call-template name="has-symbol"/></xsl:variable>
    <xsl:if test="@face|@FACE and $symbol!='yes'">
      <xsl:text>font-family:</xsl:text>
      <xsl:value-of select="@face|@FACE"/>
      <xsl:text>;</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="has-symbol">
    <xsl:if test="@face|@FACE and translate(@face|@FACE, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='symbol'">yes</xsl:if>
  </xsl:template>
  
  <xsl:template name="symbol-content">
    <xsl:for-each select="node()">
      <xsl:choose>
        <xsl:when test="self::text()">
          <xsl:value-of select="translate(., 'ABGDEZHQIKLMNXOPRSTUFCYWabgdezhqiklmnxoprVstufcywJjv¡', 'ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθικλμνξοπρςστυφχψωϑϕϖϒ')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  
  
  <xsl:template match="center">
    <div style="text-align: center; margin: 0 auto">
      <xsl:apply-templates select="node()"/>
    </div>
  </xsl:template>
  
  
  <xsl:template match = "@*|node()">
    <xsl:copy>
      <xsl:for-each select="@*">
        <xsl:attribute name="{translate(name(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')}">
          <xsl:value-of select="."/>
        </xsl:attribute>
      </xsl:for-each>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
