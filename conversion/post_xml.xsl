<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output method="xml" indent="no" encoding="UTF-8"/>

  <xsl:variable name="inline-elements">|startouttext|endouttext|stringresponse|optionresponse|numericalresponse|formularesponse|mathresponse|organicresponse|reactionresponse|customresponse|externalresponse|textline|display|img|windowlink|m|chem|num|parse|algebra|displayweight|displaystudentphoto|span|a|strong|em|b|i|sup|sub|code|kbd|samp|tt|ins|del|var|small|big|font|basefont|input|select|textarea|label|button|u|</xsl:variable>
  
  <xsl:template match="/">
    <loncapa>
      <xsl:for-each select="//head">
        <htmlhead>
          <xsl:apply-templates select="*[name()!='meta']"/>
        </htmlhead>
      </xsl:for-each>
      <xsl:for-each select="//body">
        <xsl:if test="@*">
          <htmlbody><xsl:apply-templates select="@*"/></htmlbody>
        </xsl:if>
      </xsl:for-each>
      <xsl:apply-templates select="//meta"/>
      <xsl:apply-templates/>
    </loncapa>
  </xsl:template>
  
  <!-- elements that can contain paragraphs -->
  <xsl:template match="problem|foil|item|hintgroup|hintpart|part|problemtype|window|block|while|postanswerdate|preduedate|solved|notsolved|languageblock|translated|lang|instructorcomment|windowlink|togglebox|standalone|div">
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
  
  <xsl:template match="meta">
    <xsl:variable name="names">|abstract|author|authorspace|avetries|avetries_list|clear|comefrom|comefrom_list|copyright|correct|count|course|course_list|courserestricted|creationdate|dependencies|depth|difficulty|difficulty_list|disc|disc_list|domain|end|field|firstname|generation|goto|goto_list|groupname|helpful|highestgradelevel|hostname|id|keynum|keywords|language|lastname|lastrevisiondate|lowestgradelevel|middlename|mime|modifyinguser|notes|owner|permanentemail|scope|sequsage|sequsage_list|standards|start|stdno|stdno_list|subject|technical|title|url|username|value|version|</xsl:variable>
    <xsl:if test="contains($names, concat('|',translate(@name|@NAME, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'|'))">
      <lcmeta name="{translate(@name|@NAME, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')}" content="{@content|@CONTENT}"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="script">
    <xsl:choose>
      <xsl:when test="@type='loncapa/perl'">
        <perl>
          <xsl:apply-templates/>
        </perl>
      </xsl:when>
      <xsl:otherwise>
        <!-- remove // added by tidy at the start and end -->
        <xsl:copy>
          <xsl:apply-templates select="@*"/>
          <xsl:choose>
            <xsl:when test="starts-with(normalize-space(.),'//') and substring(normalize-space(.), string-length(normalize-space(.))-1)='//'">
              <xsl:call-template name="substring-before-last">
                <xsl:with-param name="s" select="substring-after(.,'//')"/>
                <xsl:with-param name="delim" select="'//'"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="node()"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="substring-before-last">
    <xsl:param name="s"/>
    <xsl:param name="delim"/>
    <xsl:if test="contains($s, $delim)">
      <xsl:value-of select="substring-before($s, $delim)"/>
      <xsl:if test="contains(substring-after($s, $delim), $delim)">
        <xsl:value-of select="$delim"/>
        <xsl:call-template name="substring-before-last">
          <xsl:with-param name="s" select="substring-after($s,$delim)"/>
          <xsl:with-param name="delim" select="$delim"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="font">
    <!-- empty font elements and fonts containing block elements have already been removed -->
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
  </xsl:template>
  
  <xsl:template name="color">
    <xsl:if test="@color|@COLOR">
      <xsl:text>color:</xsl:text>
      <xsl:for-each select="@color|@COLOR">
        <xsl:choose>
          <xsl:when test="starts-with(., 'x')">
            <xsl:value-of select="concat('#', substring(., 2))"/>
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
          <xsl:call-template name="paragraphs"/>
        </div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
  <xsl:template match="table">
    <!-- turning some deprecated attributes into CSS (@border, @cellpadding and @cellspacing are not changed) -->
    <table>
      <xsl:choose>
        <xsl:when test="parent::center or @align or @width or @height or @bgcolor">
          <xsl:apply-templates select="@*[name()!='style' and name()!='align' and name()!='width' and name()!='height' and name()!='bgcolor']"/>
          <xsl:attribute name="style">
            <xsl:if test="parent::center or normalize-space(@align)='center'">
              <xsl:text>margin-left:auto; margin-right:auto; </xsl:text>
            </xsl:if>
            <xsl:if test="normalize-space(@align)='left' or normalize-space(@align)='right'">
              <xsl:text>float:</xsl:text>
              <xsl:value-of select="normalize-space(@align)"/>
              <xsl:text>; </xsl:text>
            </xsl:if>
            <xsl:if test="normalize-space(@width)!=''">
              <xsl:text>width:</xsl:text>
              <xsl:choose>
                <xsl:when test="contains(@width, '%')">
                  <xsl:value-of select="@width"/><xsl:text>; </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="@width"/><xsl:text>px; </xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>
            <!-- note: the height attribute is removed with no replacement -->
            <xsl:if test="normalize-space(@bgcolor)!=''">
              <xsl:text>background-color:</xsl:text>
              <xsl:choose>
                <xsl:when test="starts-with(@bgcolor, 'x')">
                  <xsl:value-of select="concat('#', substring(@bgcolor, 2))"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="@bgcolor"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:text>; </xsl:text>
            </xsl:if>
            <xsl:value-of select="@style"/>
          </xsl:attribute>
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
    <!--
      <xsl:copy>
        <xsl:if test="@clear!=''">
          <xsl:attribute name="style"><xsl:value-of select="concat('clear: ', @clear)"/></xsl:attribute>
        </xsl:if>
      </xsl:copy>
    -->
  </xsl:template>
  
  <xsl:template match="p">
    <xsl:choose>
      <xsl:when test="count(*)+count(text()[normalize-space(.)!='']) &gt; 0">
        <xsl:call-template name="paragraphs"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates select="@*"/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match = "@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
  
<!-- Reorganize a block by moving text and inline elements inside paragraphs, to avoid mixing text and block elements.
  br elements are replaced by new paragraphs. -->
  <xsl:template name="paragraphs">
    <xsl:variable name="ignored-inline">|startouttext|endouttext|displayweight|displaystudentphoto|</xsl:variable>
    <xsl:choose>
      <xsl:when test="count(*[not(contains($inline-elements, concat('|',name(),'|')))]) &gt; 0">
        <xsl:if test="count(*[not(contains($inline-elements, concat('|',name(),'|')))][1]/preceding-sibling::*[not(contains($ignored-inline, concat('|',name(),'|')))])!=0 or normalize-space(*[not(contains($inline-elements, concat('|',name(),'|')))][1]/preceding-sibling::node())!=''">
          <p><xsl:apply-templates select="*[not(contains($inline-elements, concat('|',name(),'|')))][1]/preceding-sibling::node()"/></p>
        </xsl:if>
        <xsl:for-each select="*[not(contains($inline-elements, concat('|',name(),'|')))]">
          <xsl:if test="not(contains($inline-elements, concat('|',name(),'|')))">
            <xsl:apply-templates select="."/>
          </xsl:if>
          <xsl:if test="position()!=last()">
            <xsl:variable name="next" select="generate-id(following-sibling::*[not(contains($inline-elements, concat('|',name(),'|')))][1])"/>
            <xsl:if test="count(following-sibling::*[generate-id(following-sibling::*[not(contains($inline-elements, concat('|',name(),'|')))][1]) = $next][not(contains($ignored-inline, concat('|',name(),'|')))])!=0 or normalize-space(following-sibling::node()[generate-id(following-sibling::*[not(contains($inline-elements, concat('|',name(),'|')))][1]) = $next])!=''">
              <p><xsl:apply-templates select="following-sibling::node()[generate-id(following-sibling::*[not(contains($inline-elements, concat('|',name(),'|')))][1]) = $next]"/></p>
            </xsl:if>
          </xsl:if>
        </xsl:for-each>
        <xsl:if test="count(*[not(contains($inline-elements, concat('|',name(),'|')))][position()=last()]/following-sibling::*[not(contains($ignored-inline, concat('|',name(),'|')))])!=0 or normalize-space(*[not(contains($inline-elements, concat('|',name(),'|')))][position()=last()]/following-sibling::node())!=''">
          <p><xsl:apply-templates select="*[not(contains($inline-elements, concat('|',name(),'|')))][position()=last()]/following-sibling::node()"/></p>
        </xsl:if>
      </xsl:when>
      <xsl:when test="count(*)+count(text()[normalize-space(.)!='']) &gt; 0">
        <p><xsl:apply-templates/></p>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
