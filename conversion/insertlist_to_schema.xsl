<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="1.0">

    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    
    <xsl:template match="insertlist">
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xml:lang="en">
            <xsl:call-template name="create-types"/>
            <xsl:apply-templates select="tag[not(contains(@name,'::'))]"/>
        </xs:schema>
    </xsl:template>
    
    <xsl:template name="create-types">
        <xsl:for-each select="tag[contains(@name,'::')]">
            <xs:complexType name="{translate(@name, ':', '-')}">
                <xsl:if test="description">
                    <xs:annotation>
                        <xs:documentation>
                            <xsl:value-of select="description"/>
                        </xs:documentation>
                    </xs:annotation>
                </xsl:if>
                <xsl:if test="allow!=''">
                    <xs:choice minOccurs="0" maxOccurs="unbounded">
                        <xsl:call-template name="add-children">
                            <xsl:with-param name="allow"><xsl:value-of select="allow"/></xsl:with-param>
                        </xsl:call-template>
                    </xs:choice>
                </xsl:if>
            </xs:complexType>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="tag">
        <xsl:variable name="name">
            <xsl:choose>
                <xsl:when test="contains(@name,'::')"><xsl:value-of select="substring-after(@name,'::')"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="@name"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xs:element name="{$name}">
            <xsl:if test="description">
                <xs:annotation>
                    <xs:documentation>
                        <xsl:value-of select="description"/>
                    </xs:documentation>
                </xs:annotation>
            </xsl:if>
            <xsl:if test="allow!=''">
                <xs:complexType>
                    <xs:choice minOccurs="0" maxOccurs="unbounded">
                        <xsl:call-template name="add-children">
                            <xsl:with-param name="allow"><xsl:value-of select="allow"/></xsl:with-param>
                        </xsl:call-template>
                    </xs:choice>
                </xs:complexType>
            </xsl:if>
        </xs:element>
    </xsl:template>
    
    <xsl:template name="add-children">
        <xsl:param name="allow"/>
        <xsl:choose>
            <xsl:when test="contains($allow,',')">
                <xsl:call-template name="add-child">
                    <xsl:with-param name="name"><xsl:value-of select="substring-before($allow,',')"/></xsl:with-param>
                </xsl:call-template>
                <xsl:call-template name="add-children">
                    <xsl:with-param name="allow" select="substring-after($allow,',')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$allow!=''">
                    <xsl:call-template name="add-child">
                        <xsl:with-param name="name"><xsl:value-of select="$allow"/></xsl:with-param>
                    </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="add-child">
        <xsl:param name="name"/>
        <xsl:choose>
            <xsl:when test="contains($name,'::')">
                <xsl:for-each select="/insertlist/tag[@name=$name]">
                    <xs:element name="{substring-after(@name,'::')}" type="{translate(@name, ':', '-')}"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xs:element ref="{$name}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
