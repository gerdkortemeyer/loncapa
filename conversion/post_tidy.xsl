<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output method="xml" indent="no" encoding="UTF-8"/>

  <xsl:template match="/">
    <loncapa>
      <xsl:if test="/html/head/title!='' or //htmlhead/*[name()!='title']">
        <htmlhead>
          <xsl:apply-templates select="/html/head/title"/>
          <xsl:for-each select="//htmlhead">
            <xsl:apply-templates/>
          </xsl:for-each>
        </htmlhead>
      </xsl:if>
      <xsl:for-each select="//htmlbody">
        <xsl:if test="@*">
          <htmlbody><xsl:apply-templates select="@*"/></htmlbody>
        </xsl:if>
      </xsl:for-each>
      <xsl:apply-templates/>
    </loncapa>
  </xsl:template>
  
  <xsl:template match="problem|foil|item|hintgroup|hintpart|label|part|problemtype|window|block|while|postanswerdate|preduedate|solved|notsolved|languageblock|translated|lang|instructorcomment|windowlink|togglebox|standalone|htmlbody|div">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:call-template name="paragraphs"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="html">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="head">
  </xsl:template>
  
  <xsl:template match="body">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="htmlhead">
  </xsl:template>
  
  <xsl:template match="htmlbody">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="emptyfont">
    <!-- just get rid of them
    <xsl:element name="font">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
    -->
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
        <xsl:when test="$csscolor = '' and $csssize = '' and $cssface = '' and $symbol != 'yes'">
          <xsl:apply-templates select="node()"/>
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
      <xsl:choose>
        <xsl:when test="$csscolor = '' and $csssize = '' and $cssface = '' and $symbol != 'yes'">
          <xsl:apply-templates select="node()"/>
        </xsl:when>
        <xsl:otherwise>
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
        </xsl:otherwise>
      </xsl:choose>
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
  
  <xsl:template match="basefont">
  </xsl:template>
  
  
  <xsl:template match="center">
    <xsl:choose>
      <xsl:when test="table">
        <xsl:apply-templates select="node()"/>
      </xsl:when>
      <xsl:otherwise>
        <div style="text-align: center; margin: 0 auto">
          <xsl:apply-templates select="node()"/>
        </div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
  <xsl:template match="table">
    <table>
      <xsl:choose>
        <xsl:when test="parent::center">
          <xsl:apply-templates select="@*[name()!='style']"/>
          <xsl:attribute name="style">margin-left:auto; margin-right:auto;<xsl:value-of select="@style"/></xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="@*"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="node()"/>
    </table>
  </xsl:template>
  
  <!-- removed elements -->
  <xsl:template match="startouttext">
  </xsl:template>
  
  <xsl:template match="endouttext">
  </xsl:template>
  
  <xsl:template match="startpartmarker">
  </xsl:template>
  
  <xsl:template match="endpartmarker">
  </xsl:template>
  
  <xsl:template match="displayweight">
  </xsl:template>
  
  <xsl:template match="displaystudentphoto">
  </xsl:template>
  
  <xsl:template match="displaytitle">
  </xsl:template>
  
  <xsl:template match="displayduedate">
  </xsl:template>
  
  <xsl:template match="allow">
  </xsl:template>
  
  <xsl:template match="br">
    <!-- replaced by paragraphs -->
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
  
<!-- Reorganize a block by moving text and inline elements inside paragraphs, to avoid mixing text and block elements.
  br elements are replaced by new paragraphs. -->
  <xsl:template name="paragraphs">
    <xsl:variable name="inline-elements">|textline|display|img|windowlink|m|chem|num|parse|algebra|displayweight|displaystudentphoto|inlinefont|span|a|strong|em|b|i|sup|sub|code|kbd|samp|tt|ins|del|var|small|big|font|basefont|hr|input|select|textarea|label|button|u|</xsl:variable>
    <xsl:choose>
      <xsl:when test="count(*[not(contains($inline-elements, concat('|',name(),'|')))]) &gt; 0">
        <xsl:if test="count(*[not(contains($inline-elements, concat('|',name(),'|')))][1]/preceding-sibling::*)!=0 or normalize-space(*[not(contains($inline-elements, concat('|',name(),'|')))][1]/preceding-sibling::node())!=''">
          <p>
            <xsl:apply-templates select="*[not(contains($inline-elements, concat('|',name(),'|')))][1]/preceding-sibling::node()"/>
          </p>
        </xsl:if>
        <xsl:for-each select="*[not(contains($inline-elements, concat('|',name(),'|')))]">
          <xsl:if test="not(contains($inline-elements, concat('|',name(),'|')))">
            <xsl:apply-templates select="."/>
          </xsl:if>
          <xsl:if test="position()!=last()">
            <xsl:variable name="next" select="generate-id(following-sibling::*[not(contains($inline-elements, concat('|',name(),'|')))][1])"/>
            <xsl:if test="count(following-sibling::*[generate-id(following-sibling::*[not(contains($inline-elements, concat('|',name(),'|')))][1]) = $next])!=0 or normalize-space(following-sibling::node()[generate-id(following-sibling::*[not(contains($inline-elements, concat('|',name(),'|')))][1]) = $next])!=''">
              <p>
                <xsl:apply-templates select="following-sibling::node()[generate-id(following-sibling::*[not(contains($inline-elements, concat('|',name(),'|')))][1]) = $next]"/>
              </p>
            </xsl:if>
          </xsl:if>
        </xsl:for-each>
        <xsl:if test="count(*[not(contains($inline-elements, concat('|',name(),'|')))][position()=last()]/following-sibling::*)!=0 or normalize-space(*[not(contains($inline-elements, concat('|',name(),'|')))][position()=last()]/following-sibling::node())!=''">
          <p>
            <xsl:apply-templates select="*[not(contains($inline-elements, concat('|',name(),'|')))][position()=last()]/following-sibling::node()"/>
          </p>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <p>
          <xsl:apply-templates/>
        </p>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
