// https://nvd.nist.gov/vuln/data-feeds#JSON_FEED
UNWIND ['2002.json', '2003.json', '2004.json', '2005.json', '2006.json', '2007.json',
        '2008.json', '2009.json', '2010.json', '2011.json', '2012.json', '2013.json',
        '2014.json', '2015.json', '2016.json', '2017.json', '2018.json', '2019.json', '2020.json'] as filename

CALL apoc.load.json(filename) YIELD value AS nvd
UNWIND nvd.CVE_Items as vuln

MERGE (cve:CVE { name: vuln.cve.CVE_data_meta.ID })
SET cve.description = [desc IN vuln.cve.description.description_data WHERE desc.lang = 'en'| desc.value],
    cve.published = apoc.date.fromISO8601(apoc.text.replace(vuln.publishedDate,'Z$',':00Z'))

FOREACH(ignoreMe IN CASE WHEN vuln.impact.baseMetricV2 THEN [1] ELSE [] END | 
    MERGE (cvss2:CVSS2 { name: vuln.cve.CVE_data_meta.ID + '_CVSS2' })
    SET cvss2.access_complexity = vuln.impact.baseMetricV2.cvssV2.accessComplexity,
        cvss2.authentication = vuln.impact.baseMetricV2.cvssV2.authentication,
        cvss2.availability_impact = vuln.impact.baseMetricV2.cvssV2.availabilityImpact,
        cvss2.base_score = vuln.impact.baseMetricV2.cvssV2.baseScore,
        cvss2.confidentiality_impact = vuln.impact.baseMetricV2.cvssV2.confidentialityImpact,
        cvss2.exploitability_score = vuln.impact.baseMetricV2.exploitabilityScore,
        cvss2.impact_score = vuln.impact.baseMetricV2.impactScore,
        cvss2.integrity_impact = vuln.impact.baseMetricV2.cvssV2.integrityImpact,
        cvss2.severity = vuln.impact.baseMetricV2.severity,
        cvss2.obtain_all_privilege = vuln.impact.baseMetricV2.obtainAllPrivilege,
        cvss2.obtain_other_privilege = vuln.impact.baseMetricV2.obtainOtherPrivilege,
        cvss2.obtain_user_privilege = vuln.impact.baseMetricV2.obtainUserPrivilege,
        cvss2.user_interaction_required = vuln.impact.baseMetricV2.userInteractionRequired,
        cvss2.vector_string = vuln.impact.baseMetricV2.cvssV2.vectorString,
        cvss2.access_vector = vuln.impact.baseMetricV2.cvssV2.accessVector
    MERGE (cve)-[:SCORED]->(cvss2)
)

FOREACH(ignoreMe IN CASE WHEN vuln.impact.baseMetricV3 THEN [1] ELSE [] END | 
    MERGE (cvss3:CVSS3 { name: vuln.cve.CVE_data_meta.ID + '_CVSS3' })
    SET cvss3.attack_complexity = vuln.impact.baseMetricV3.cvssV3.attackComplexity,
        cvss3.availability_impact = vuln.impact.baseMetricV3.cvssV3.availabilityImpact,
        cvss3.base_score = vuln.impact.baseMetricV3.cvssV3.baseScore,
        cvss3.base_severity = vuln.impact.baseMetricV3.cvssV3.baseSeverity,
        cvss3.confidentiality_impact = vuln.impact.baseMetricV3.cvssV3.confidentialityImpact,
        cvss3.exploitability_score = vuln.impact.baseMetricV3.exploitabilityScore,
        cvss3.impact_score = vuln.impact.baseMetricV3.impactScore,
        cvss3.integrity_impact = vuln.impact.baseMetricV3.cvssV3.integrityImpact,
        cvss3.privileges_required = vuln.impact.baseMetricV3.cvssV3.privilegesRequired,
        cvss3.scope = vuln.impact.baseMetricV3.cvssV3.scope,
        cvss3.user_interaction = vuln.impact.baseMetricV3.cvssV3.userInteraction,
        cvss3.vector_string = vuln.impact.baseMetricV3.cvssV3.vectorString,
        cvss3.attack_vector = vuln.impact.baseMetricV3.cvssV3.attackVector
    MERGE (cve)-[:SCORED]->(cvss3)
)

FOREACH (vendor_data IN vuln.cve.affects.vendor.vendor_data |
        MERGE (vendor:Vendor {name: vendor_data.vendor_name})

        FOREACH (product_data IN vendor_data.product.product_data |
            MERGE (product:Product {name: product_data.product_name})
            MERGE (product)-[:MADE_BY]->(vendor)

            FOREACH (version_data IN product_data.version.version_data |
                MERGE (product_version:ProductVersion {
                    name: vendor_data.vendor_name + '_' + product_data.product_name + '_' + version_data.version_affected + version_data.version_value
                })
                SET product_version.version_value = version_data.version_value
                MERGE (product_version)-[:VERSION_OF]->(product)
                MERGE (cve)-[:AFFECTS]->(product_version))
            )
    )

FOREACH (problemtype_data IN vuln.cve.problemtype.problemtype_data |
        FOREACH (description IN problemtype_data.description |
            MERGE (cwe:CWE {name: description.value})
            MERGE (cve)-[:PROBLEM_TYPE]->(cwe)
        )
)

FOREACH (reference_data IN vuln.cve.reference_data |
        MERGE (ref:Reference {
            url: reference_data.url
        })
        SET ref.name = reference_data.name,
            ref.source = reference_data.refsource
        MERGE (cve)-[:REFERENCE]->(ref)
);