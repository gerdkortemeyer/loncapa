# The LearningOnline Network with CAPA - LON-CAPA
# Serves up the table of contents in JSON
#
# Copyright (C) 2014 Michigan State University Board of Trustees
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
package Apache::lc_ui_contents;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common);
use Apache::lc_entity_sessions();
use Apache::lc_entity_users();
use Apache::lc_ui_utils;
use Apache::lc_json_utils();
use Apache::lc_logs;

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
   $r->content_type('application/json; charset=utf-8');
   $r->print(<<ENDCONTENTS);
[
    
    {
        "parent":"#",
        "text":"current current current fusion",
        "id":"jQTfHfgZBBqQv1mGYmd_25271_1406233152"
    },
    
    {
        "parent":"#",
        "text":"Chapter energy electronic current current",
        "id":"jWMs9bkriLmELfieoBr_25271_1406233152"
    },
    
    {
        "parent":"jWMs9bkriLmELfieoBr_25271_1406233152",
        "text":"current fusion field",
        "id":"k893nETGyS1MZnRqx2x_25271_1406233152"
    },
    
    {
        "parent":"jWMs9bkriLmELfieoBr_25271_1406233152",
        "text":"Chapter current energy fusion",
        "id":"kdRLyLDUsP26hK4TRtv_25271_1406233152"
    },
    
    {
        "parent":"kdRLyLDUsP26hK4TRtv_25271_1406233152",
        "text":"Chapter field field current field",
        "id":"kjuBAs8prsoLV8spRip_25271_1406233152"
    },
    
    {
        "parent":"kjuBAs8prsoLV8spRip_25271_1406233152",
        "text":"Chapter field resistance energy",
        "id":"kpvMfb6COYywr6akew9_25271_1406233152"
    },
    
    {
        "parent":"kpvMfb6COYywr6akew9_25271_1406233152",
        "text":"fusion energy current field",
        "id":"kBjEbphrWCPynhYTpF7_25271_1406233152"
    },
    
    {
        "parent":"kpvMfb6COYywr6akew9_25271_1406233152",
        "text":"electronic resistance current",
        "id":"kOkc3rP3G9WRqBJLOTL_25271_1406233152"
    },
    
    {
        "parent":"kpvMfb6COYywr6akew9_25271_1406233152",
        "text":"capacity field electronic capacity",
        "id":"l0scvZ9vGBQn3OZU8IF_25271_1406233152"
    },
    
    {
        "parent":"kpvMfb6COYywr6akew9_25271_1406233152",
        "text":"capacity current capacity electronic",
        "id":"lbPqLtjRYqGosZy1yRH_25271_1406233152"
    },
    
    {
        "parent":"kpvMfb6COYywr6akew9_25271_1406233152",
        "text":"energy current resistance energy",
        "id":"lnyGAircebFz6hutYOt_25271_1406233152"
    },
    
    {
        "parent":"kpvMfb6COYywr6akew9_25271_1406233152",
        "text":"energy electronic resistance energy",
        "id":"lzjCrOu9Tb7McZo4uEp_25271_1406233152"
    },
    
    {
        "parent":"kpvMfb6COYywr6akew9_25271_1406233152",
        "text":"field field field",
        "id":"lKOOU5zhRmbJRTIyRLX_25271_1406233152"
    },
    
    {
        "parent":"kpvMfb6COYywr6akew9_25271_1406233152",
        "text":"fusion electronic capacity",
        "id":"lWe9cWoGUdC3RQd5Uhr_25271_1406233152"
    },
    
    {
        "parent":"kjuBAs8prsoLV8spRip_25271_1406233152",
        "text":"energy electronic energy",
        "id":"m7f8SKKnycfiZdnezo5_25271_1406233152"
    },
    
    {
        "parent":"kjuBAs8prsoLV8spRip_25271_1406233152",
        "text":"electronic energy energy field",
        "id":"mivRXO3TSZgNyo6tnd7_25271_1406233152"
    },
    
    {
        "parent":"kdRLyLDUsP26hK4TRtv_25271_1406233152",
        "text":"resistance resistance electronic",
        "id":"muCCokc7Q0OwPxoL7C9_25271_1406233152"
    },
    
    {
        "parent":"jWMs9bkriLmELfieoBr_25271_1406233152",
        "text":"Chapter energy capacity energy resistance",
        "id":"mAHm8LTjHTXZm10zrQR_25271_1406233152"
    },
    
    {
        "parent":"mAHm8LTjHTXZm10zrQR_25271_1406233152",
        "text":"capacity capacity capacity",
        "id":"mMya9Ic0id3Q7GK7iiR_25271_1406233152"
    },
    
    {
        "parent":"mAHm8LTjHTXZm10zrQR_25271_1406233152",
        "text":"field fusion electronic",
        "id":"mZ4ieX8t1DGNzNl0ehX_25271_1406233152"
    },
    
    {
        "parent":"mAHm8LTjHTXZm10zrQR_25271_1406233152",
        "text":"field current resistance resistance",
        "id":"nbo30kYmSIRAwWh3dkZ_25271_1406233152"
    },
    
    {
        "parent":"mAHm8LTjHTXZm10zrQR_25271_1406233152",
        "text":"electronic current current",
        "id":"nnIQNp8N7kkwMtbj0zf_25271_1406233152"
    },
    
    {
        "parent":"mAHm8LTjHTXZm10zrQR_25271_1406233152",
        "text":"capacity electronic electronic energy",
        "id":"nzsjCz7P2Znktr7pbKF_25271_1406233152"
    },
    
    {
        "parent":"jWMs9bkriLmELfieoBr_25271_1406233152",
        "text":"field field electronic",
        "id":"nKJFID2spuzIdDPzhhD_25271_1406233152"
    },
    
    {
        "parent":"jWMs9bkriLmELfieoBr_25271_1406233152",
        "text":"Chapter fusion field current",
        "id":"nR2SQivfULLDPR2DaOR_25271_1406233152"
    },
    
    {
        "parent":"nR2SQivfULLDPR2DaOR_25271_1406233152",
        "text":"Chapter electronic capacity field field",
        "id":"nWWVjA1wjxVYkMWJE0F_25271_1406233152"
    },
    
    {
        "parent":"nWWVjA1wjxVYkMWJE0F_25271_1406233152",
        "text":"Chapter resistance field field field",
        "id":"o2B1nhIflBEqkfi6dfr_25271_1406233152"
    },
    
    {
        "parent":"o2B1nhIflBEqkfi6dfr_25271_1406233152",
        "text":"current field field field",
        "id":"odWMApOFU652jFSJiJX_25271_1406233152"
    },
    
    {
        "parent":"o2B1nhIflBEqkfi6dfr_25271_1406233152",
        "text":"resistance electronic current energy",
        "id":"optf4I61VHuMkEb4fhn_25271_1406233152"
    },
    
    {
        "parent":"o2B1nhIflBEqkfi6dfr_25271_1406233152",
        "text":"electronic energy field",
        "id":"oB07zG6Nj71MsYsGIi5_25271_1406233152"
    },
    
    {
        "parent":"o2B1nhIflBEqkfi6dfr_25271_1406233152",
        "text":"electronic resistance electronic electronic",
        "id":"oMfaC2uGeFAeyJeNqdX_25271_1406233152"
    },
    
    {
        "parent":"o2B1nhIflBEqkfi6dfr_25271_1406233152",
        "text":"current current current",
        "id":"oXJx2Y6ZvepFYVAIKoV_25271_1406233152"
    },
    
    {
        "parent":"o2B1nhIflBEqkfi6dfr_25271_1406233152",
        "text":"energy field resistance",
        "id":"p96yi7pE79c4kq9cpjj_25271_1406233152"
    },
    
    {
        "parent":"o2B1nhIflBEqkfi6dfr_25271_1406233152",
        "text":"resistance electronic fusion current",
        "id":"pkt9wAYTnfRcyyIoxKp_25271_1406233152"
    },
    
    {
        "parent":"o2B1nhIflBEqkfi6dfr_25271_1406233152",
        "text":"field resistance field field",
        "id":"pvBUoRnE1GEKRZFgoAV_25271_1406233152"
    },
    
    {
        "parent":"o2B1nhIflBEqkfi6dfr_25271_1406233152",
        "text":"current capacity field",
        "id":"pGIzdL7lV4S0AEFID4Z_25271_1406233152"
    },
    
    {
        "parent":"o2B1nhIflBEqkfi6dfr_25271_1406233152",
        "text":"energy resistance field current",
        "id":"pRMUYXkjnwrkERK7tXX_25271_1406233152"
    },
    
    {
        "parent":"nR2SQivfULLDPR2DaOR_25271_1406233152",
        "text":"current field current current",
        "id":"q3pSDGsvm9FBvPRl2Pn_25271_1406233152"
    },
    
    {
        "parent":"nR2SQivfULLDPR2DaOR_25271_1406233152",
        "text":"Chapter resistance current energy resistance",
        "id":"q9Wj6yuGroydRIHNWff_25271_1406233152"
    },
    
    {
        "parent":"q9Wj6yuGroydRIHNWff_25271_1406233152",
        "text":"energy resistance field",
        "id":"qm1AuIyYF5GxJ82BlZL_25271_1406233152"
    },
    
    {
        "parent":"q9Wj6yuGroydRIHNWff_25271_1406233152",
        "text":"Chapter current fusion resistance field",
        "id":"qs8dic3vC7mFMHBbxmh_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"fusion current electronic",
        "id":"qDjHePIq3iVpRWtoihb_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"energy resistance current field",
        "id":"qOti8rzZplXuq5oPc4h_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"resistance resistance energy resistance",
        "id":"qZZ7BJgepfclg1IeQTL_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"current resistance fusion energy",
        "id":"rbUxK4CpRrA3kBjTsxX_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"resistance current electronic",
        "id":"ro0s9fhP6QTgn2DCa0p_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"capacity electronic resistance",
        "id":"ryUjDCbyM5x5tnZWV57_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"resistance resistance current",
        "id":"rJYFoOowex6pxB4lLY5_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"fusion current current",
        "id":"rVrLNIOBrFA4BJsqwJb_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"current electronic fusion",
        "id":"s7aOCd4e1wvCblpfbrj_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"fusion electronic current",
        "id":"siNmggt0ElCCUXxbdPr_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"current electronic energy",
        "id":"suptTE8nVmCnxdFPJKh_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"resistance electronic energy",
        "id":"sFu2Fbd33IfkF6JSlRT_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"capacity field resistance resistance",
        "id":"sRampicvQOpGsULm6vD_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"resistance field energy resistance",
        "id":"t2tOyIMbYmcmNTpVOp3_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"energy fusion electronic",
        "id":"tdUbTfW7oJUQ6dSFF5L_25271_1406233152"
    },
    
    {
        "parent":"qs8dic3vC7mFMHBbxmh_25271_1406233152",
        "text":"energy resistance fusion capacity",
        "id":"tpzsBGB3OjN2BDVWByh_25271_1406233152"
    },
    
    {
        "parent":"q9Wj6yuGroydRIHNWff_25271_1406233152",
        "text":"field resistance fusion",
        "id":"tAMpAGjTYPLc6CLDH7H_25271_1406233152"
    },
    
    {
        "parent":"q9Wj6yuGroydRIHNWff_25271_1406233152",
        "text":"resistance resistance current field",
        "id":"tMrGj6YQopDoC2OUDAd_25271_1406233152"
    },
    
    {
        "parent":"q9Wj6yuGroydRIHNWff_25271_1406233152",
        "text":"current energy electronic",
        "id":"tXpWUy4nfDvrXC3IoCt_25271_1406233152"
    },
    
    {
        "parent":"q9Wj6yuGroydRIHNWff_25271_1406233152",
        "text":"Chapter electronic resistance resistance current",
        "id":"u2RfDIV83xEtkKKXurT_25271_1406233152"
    },
    
    {
        "parent":"u2RfDIV83xEtkKKXurT_25271_1406233152",
        "text":"resistance electronic current",
        "id":"uezfqwQefShRBYJzkYN_25271_1406233152"
    },
    
    {
        "parent":"u2RfDIV83xEtkKKXurT_25271_1406233152",
        "text":"current resistance fusion resistance",
        "id":"upVdDZOmugM6F5jQbHX_25271_1406233152"
    },
    
    {
        "parent":"u2RfDIV83xEtkKKXurT_25271_1406233152",
        "text":"resistance resistance capacity",
        "id":"uC316ch6OOBZeCAkKid_25271_1406233152"
    },
    
    {
        "parent":"u2RfDIV83xEtkKKXurT_25271_1406233152",
        "text":"electronic electronic field electronic",
        "id":"uNcbZ8pgP3wNFpwu7C1_25271_1406233152"
    },
    
    {
        "parent":"u2RfDIV83xEtkKKXurT_25271_1406233152",
        "text":"current current field",
        "id":"uYnsVrctAl1UGYp37ih_25271_1406233152"
    },
    
    {
        "parent":"q9Wj6yuGroydRIHNWff_25271_1406233152",
        "text":"current resistance field resistance",
        "id":"va4pGyN3p9n9FOps9DX_25271_1406233152"
    },
    
    {
        "parent":"q9Wj6yuGroydRIHNWff_25271_1406233152",
        "text":"Chapter current energy electronic electronic",
        "id":"vfAXy9iq6EYVwSXJinv_25271_1406233152"
    },
    
    {
        "parent":"vfAXy9iq6EYVwSXJinv_25271_1406233152",
        "text":"current current capacity current",
        "id":"vqQQBR97JPLTRlIp3fX_25271_1406233152"
    },
    
    {
        "parent":"vfAXy9iq6EYVwSXJinv_25271_1406233152",
        "text":"resistance energy electronic capacity",
        "id":"vDlvEK1EJVZrTIlNEAx_25271_1406233152"
    },
    
    {
        "parent":"vfAXy9iq6EYVwSXJinv_25271_1406233152",
        "text":"energy capacity electronic",
        "id":"vOHgRS85iqq3T8WqK53_25271_1406233152"
    },
    
    {
        "parent":"vfAXy9iq6EYVwSXJinv_25271_1406233152",
        "text":"energy electronic energy",
        "id":"vZWjUevYdYYvYTIxs0V_25271_1406233152"
    },
    
    {
        "parent":"vfAXy9iq6EYVwSXJinv_25271_1406233152",
        "text":"fusion field energy",
        "id":"wbGCKJXORgfPUzDcG8V_25271_1406233152"
    },
    
    {
        "parent":"vfAXy9iq6EYVwSXJinv_25271_1406233152",
        "text":"current field resistance",
        "id":"wnazaZQIM0Y1dpZQtQB_25271_1406233152"
    },
    
    {
        "parent":"vfAXy9iq6EYVwSXJinv_25271_1406233152",
        "text":"electronic energy field energy",
        "id":"wzgTAQfxneoundiQHMl_25271_1406233152"
    },
    
    {
        "parent":"vfAXy9iq6EYVwSXJinv_25271_1406233152",
        "text":"resistance field resistance energy",
        "id":"wLDNrh50mSrJdw9w7n3_25271_1406233152"
    },
    
    {
        "parent":"vfAXy9iq6EYVwSXJinv_25271_1406233152",
        "text":"field energy electronic electronic",
        "id":"wWWpzmbRMNZTjMPwMjT_25271_1406233152"
    },
    
    {
        "parent":"nR2SQivfULLDPR2DaOR_25271_1406233152",
        "text":"field energy fusion energy",
        "id":"x8cvDoUh5SQuHVzQiqZ_25271_1406233152"
    },
    
    {
        "parent":"nR2SQivfULLDPR2DaOR_25271_1406233152",
        "text":"electronic current electronic energy",
        "id":"xjR9kOY6tKxO2jEbXbz_25271_1406233152"
    },
    
    {
        "parent":"nR2SQivfULLDPR2DaOR_25271_1406233152",
        "text":"Chapter field fusion capacity resistance",
        "id":"xpHCInLoo9IqwJEotmp_25271_1406233152"
    },
    
    {
        "parent":"xpHCInLoo9IqwJEotmp_25271_1406233152",
        "text":"resistance current resistance resistance",
        "id":"xAUzHnueyFGA1Iu5yVP_25271_1406233152"
    },
    
    {
        "parent":"xpHCInLoo9IqwJEotmp_25271_1406233152",
        "text":"field energy electronic field",
        "id":"xM24xCGL9G8lZ5t6Qmt_25271_1406233152"
    },
    
    {
        "parent":"xpHCInLoo9IqwJEotmp_25271_1406233152",
        "text":"Chapter electronic resistance electronic current",
        "id":"xS198YZVM9HNUheBBdL_25271_1406233152"
    },
    
    {
        "parent":"xS198YZVM9HNUheBBdL_25271_1406233152",
        "text":"fusion capacity electronic field",
        "id":"y46QxONDlEXnT2yGxrz_25271_1406233152"
    },
    
    {
        "parent":"xS198YZVM9HNUheBBdL_25271_1406233152",
        "text":"field energy capacity",
        "id":"yftRMY6hXzJMex7aclX_25271_1406233152"
    },
    
    {
        "parent":"xS198YZVM9HNUheBBdL_25271_1406233152",
        "text":"energy current energy field",
        "id":"yqKNSmhvYgOTRnQ2LpD_25271_1406233152"
    },
    
    {
        "parent":"xS198YZVM9HNUheBBdL_25271_1406233152",
        "text":"field energy energy",
        "id":"yC1wXpB2j3QoqyzhzeF_25271_1406233152"
    },
    
    {
        "parent":"xS198YZVM9HNUheBBdL_25271_1406233152",
        "text":"energy capacity fusion field",
        "id":"yNeGWKbA9tSaZdoCq2J_25271_1406233152"
    },
    
    {
        "parent":"xS198YZVM9HNUheBBdL_25271_1406233152",
        "text":"current fusion resistance electronic",
        "id":"yYtwYLHLp8n01ib5mJX_25271_1406233152"
    },
    
    {
        "parent":"xpHCInLoo9IqwJEotmp_25271_1406233152",
        "text":"electronic electronic capacity electronic",
        "id":"z9M96QOCP3Va7yR61GN_25271_1406233152"
    },
    
    {
        "parent":"xpHCInLoo9IqwJEotmp_25271_1406233152",
        "text":"current electronic fusion resistance",
        "id":"zkSNVKykIs8pQdRygaR_25271_1406233152"
    },
    
    {
        "parent":"xpHCInLoo9IqwJEotmp_25271_1406233152",
        "text":"energy electronic electronic energy",
        "id":"zvQEwvUsdRTd4r74uJP_25271_1406233152"
    },
    
    {
        "parent":"xpHCInLoo9IqwJEotmp_25271_1406233152",
        "text":"capacity electronic fusion",
        "id":"zHmtZNAHdL83Unqu9zj_25271_1406233152"
    },
    
    {
        "parent":"xpHCInLoo9IqwJEotmp_25271_1406233152",
        "text":"electronic current electronic",
        "id":"zSFw8yqXZuNu805MkZr_25271_1406233152"
    },
    
    {
        "parent":"xpHCInLoo9IqwJEotmp_25271_1406233152",
        "text":"Chapter capacity current current energy",
        "id":"zYjCcg7H1yvW7sr8Ued_25271_1406233152"
    },
    
    {
        "parent":"zYjCcg7H1yvW7sr8Ued_25271_1406233152",
        "text":"field field field",
        "id":"A9SNKVFcPUGRUeEOKQ1_25271_1406233152"
    },
    
    {
        "parent":"zYjCcg7H1yvW7sr8Ued_25271_1406233152",
        "text":"current energy field",
        "id":"AlmxaQGp4Llq9p1ONj3_25271_1406233152"
    },
    
    {
        "parent":"zYjCcg7H1yvW7sr8Ued_25271_1406233152",
        "text":"fusion field field",
        "id":"AwMHv2YCPf0go3uUSL7_25271_1406233152"
    },
    
    {
        "parent":"zYjCcg7H1yvW7sr8Ued_25271_1406233152",
        "text":"current resistance current energy",
        "id":"AHW5ojYuvnYHSwqI1jz_25271_1406233152"
    },
    
    {
        "parent":"zYjCcg7H1yvW7sr8Ued_25271_1406233152",
        "text":"energy current field",
        "id":"AT3neejjqumQMdq5xvz_25271_1406233152"
    },
    
    {
        "parent":"zYjCcg7H1yvW7sr8Ued_25271_1406233152",
        "text":"resistance field field energy",
        "id":"B4unzM4lSAgdfzRKFUd_25271_1406233152"
    },
    
    {
        "parent":"zYjCcg7H1yvW7sr8Ued_25271_1406233152",
        "text":"capacity current current field",
        "id":"BgCo2joNT29ISN7SZJ7_25271_1406233152"
    },
    
    {
        "parent":"zYjCcg7H1yvW7sr8Ued_25271_1406233152",
        "text":"current resistance electronic resistance",
        "id":"BrVQbJYu0zWpdLMsHCx_25271_1406233152"
    },
    
    {
        "parent":"xpHCInLoo9IqwJEotmp_25271_1406233152",
        "text":"current current electronic electronic",
        "id":"BDDcXxitbcoUjXM9grv_25271_1406233152"
    },
    
    {
        "parent":"nR2SQivfULLDPR2DaOR_25271_1406233152",
        "text":"Chapter fusion field resistance fusion",
        "id":"BJkf5X73FUWb8U2uuZj_25271_1406233152"
    },
    
    {
        "parent":"BJkf5X73FUWb8U2uuZj_25271_1406233152",
        "text":"Chapter resistance fusion resistance",
        "id":"BOK4MLTSKuFN6iMfgad_25271_1406233152"
    },
    
    {
        "parent":"BOK4MLTSKuFN6iMfgad_25271_1406233152",
        "text":"energy electronic field energy",
        "id":"C0eEe2nTGXyRAb7OlzP_25271_1406233152"
    },
    
    {
        "parent":"BOK4MLTSKuFN6iMfgad_25271_1406233152",
        "text":"current field electronic resistance",
        "id":"CcgmwtJdqhHtr4yHOjn_25271_1406233152"
    },
    
    {
        "parent":"BOK4MLTSKuFN6iMfgad_25271_1406233152",
        "text":"energy current electronic energy",
        "id":"CovVb8f1LhHFcFBVyDv_25271_1406233152"
    },
    
    {
        "parent":"BOK4MLTSKuFN6iMfgad_25271_1406233152",
        "text":"electronic field resistance",
        "id":"CAkQ92KngsgQrfoHxXH_25271_1406233152"
    },
    
    {
        "parent":"BOK4MLTSKuFN6iMfgad_25271_1406233152",
        "text":"current electronic current",
        "id":"CMDKT57spVd79Gmbu49_25271_1406233152"
    },
    
    {
        "parent":"BOK4MLTSKuFN6iMfgad_25271_1406233152",
        "text":"current resistance energy electronic",
        "id":"CYpwLWDeMwTQv6el2QF_25271_1406233152"
    },
    
    {
        "parent":"BOK4MLTSKuFN6iMfgad_25271_1406233152",
        "text":"capacity fusion current field",
        "id":"DbsnHGHAX0F5cRVgPGp_25271_1406233152"
    },
    
    {
        "parent":"BOK4MLTSKuFN6iMfgad_25271_1406233152",
        "text":"electronic energy electronic fusion",
        "id":"DoqPwmA9Vvc5FpJJCyB_25271_1406233152"
    },
    
    {
        "parent":"BJkf5X73FUWb8U2uuZj_25271_1406233152",
        "text":"Chapter field resistance capacity",
        "id":"DuORLLY9YzJvEcOy2wF_25271_1406233152"
    },
    
    {
        "parent":"DuORLLY9YzJvEcOy2wF_25271_1406233152",
        "text":"current electronic current",
        "id":"DHSLJcn2wzMTEmtGDxD_25271_1406233152"
    },
    
    {
        "parent":"DuORLLY9YzJvEcOy2wF_25271_1406233152",
        "text":"field field resistance capacity",
        "id":"DUaQrThiYquE85sBwHv_25271_1406233152"
    },
    
    {
        "parent":"DuORLLY9YzJvEcOy2wF_25271_1406233152",
        "text":"capacity electronic electronic electronic",
        "id":"E64AxxHR1opjJf782sx_25271_1406233152"
    },
    
    {
        "parent":"DuORLLY9YzJvEcOy2wF_25271_1406233152",
        "text":"field field field",
        "id":"EikMdcOMo6AoFS9h4uB_25271_1406233152"
    },
    
    {
        "parent":"DuORLLY9YzJvEcOy2wF_25271_1406233152",
        "text":"electronic field current",
        "id":"EtVQOU9DhBhZZKjIMed_25271_1406233152"
    },
    
    {
        "parent":"DuORLLY9YzJvEcOy2wF_25271_1406233152",
        "text":"energy current energy",
        "id":"EFUQ2YeNeaFq4PPhkTn_25271_1406233152"
    },
    
    {
        "parent":"DuORLLY9YzJvEcOy2wF_25271_1406233152",
        "text":"current electronic resistance current",
        "id":"ERFLUuhKTa7DbxIRQJj_25271_1406233152"
    },
    
    {
        "parent":"DuORLLY9YzJvEcOy2wF_25271_1406233152",
        "text":"field current fusion",
        "id":"F30H6gVmK2jIWgkVThf_25271_1406233152"
    },
    
    {
        "parent":"DuORLLY9YzJvEcOy2wF_25271_1406233152",
        "text":"electronic field capacity",
        "id":"FfgSLW2i6KuNSTn4Vjj_25271_1406233152"
    },
    
    {
        "parent":"DuORLLY9YzJvEcOy2wF_25271_1406233152",
        "text":"resistance energy energy",
        "id":"FqSAoDYg1XninNwrUKR_25271_1406233152"
    },
    
    {
        "parent":"BJkf5X73FUWb8U2uuZj_25271_1406233152",
        "text":"field current field",
        "id":"FDovty315tWCMe7H5vj_25271_1406233152"
    },
    
    {
        "parent":"BJkf5X73FUWb8U2uuZj_25271_1406233152",
        "text":"energy resistance electronic",
        "id":"FPzs0NvkyAEXeViO4Df_25271_1406233152"
    },
    
    {
        "parent":"BJkf5X73FUWb8U2uuZj_25271_1406233152",
        "text":"energy resistance capacity",
        "id":"G0WgfBWhuBnIwJRDYiZ_25271_1406233152"
    },
    
    {
        "parent":"BJkf5X73FUWb8U2uuZj_25271_1406233152",
        "text":"resistance electronic electronic",
        "id":"GcirtpM7oTVADwryAgN_25271_1406233152"
    },
    
    {
        "parent":"BJkf5X73FUWb8U2uuZj_25271_1406233152",
        "text":"Chapter resistance energy capacity",
        "id":"GibqV0XRq9NLQ4nsfhn_25271_1406233152"
    },
    
    {
        "parent":"GibqV0XRq9NLQ4nsfhn_25271_1406233152",
        "text":"resistance electronic capacity",
        "id":"GumAsBhSzazJmrycZDX_25271_1406233152"
    },
    
    {
        "parent":"GibqV0XRq9NLQ4nsfhn_25271_1406233152",
        "text":"resistance resistance energy",
        "id":"GGVeBSCNprUfwG4N4sN_25271_1406233152"
    },
    
    {
        "parent":"GibqV0XRq9NLQ4nsfhn_25271_1406233152",
        "text":"current energy fusion",
        "id":"GSJwyMx1SUixAdSDM53_25271_1406233152"
    },
    
    {
        "parent":"GibqV0XRq9NLQ4nsfhn_25271_1406233152",
        "text":"current field electronic field",
        "id":"H4m4cPVOvJpyjQ0zOtb_25271_1406233152"
    },
    
    {
        "parent":"GibqV0XRq9NLQ4nsfhn_25271_1406233152",
        "text":"capacity resistance resistance field",
        "id":"HfWVOcoXJk3wA2bnKY9_25271_1406233152"
    },
    
    {
        "parent":"GibqV0XRq9NLQ4nsfhn_25271_1406233152",
        "text":"resistance current current current",
        "id":"Hs3Tf3oTmfESURtjgBP_25271_1406233152"
    },
    
    {
        "parent":"GibqV0XRq9NLQ4nsfhn_25271_1406233152",
        "text":"current field field",
        "id":"HDCrMIli8TEVwBI3PvH_25271_1406233152"
    },
    
    {
        "parent":"BJkf5X73FUWb8U2uuZj_25271_1406233152",
        "text":"Chapter capacity fusion current energy",
        "id":"HJxkhlknfi3MgfAJlE5_25271_1406233152"
    },
    
    {
        "parent":"HJxkhlknfi3MgfAJlE5_25271_1406233152",
        "text":"resistance current current electronic",
        "id":"HV3ZLYtqWNx9kTSI3q9_25271_1406233152"
    },
    
    {
        "parent":"HJxkhlknfi3MgfAJlE5_25271_1406233152",
        "text":"field resistance energy",
        "id":"I6LmxLNq7pZEr5SoCf7_25271_1406233152"
    },
    
    {
        "parent":"nR2SQivfULLDPR2DaOR_25271_1406233152",
        "text":"field capacity electronic electronic",
        "id":"IiuCmAUKnaYP4nOR2bT_25271_1406233152"
    },
    
    {
        "parent":"nR2SQivfULLDPR2DaOR_25271_1406233152",
        "text":"Chapter resistance resistance resistance",
        "id":"IoraTUPsSNQIhrEEEdr_25271_1406233152"
    },
    
    {
        "parent":"IoraTUPsSNQIhrEEEdr_25271_1406233152",
        "text":"energy capacity energy",
        "id":"IAvcg3Hx34DfMN1Buy5_25271_1406233152"
    },
    
    {
        "parent":"IoraTUPsSNQIhrEEEdr_25271_1406233152",
        "text":"energy field field",
        "id":"IM4AP46KxkRODfeV6ox_25271_1406233152"
    },
    
    {
        "parent":"IoraTUPsSNQIhrEEEdr_25271_1406233152",
        "text":"Chapter energy fusion capacity",
        "id":"IRItSqVLTuwDz1ADUoF_25271_1406233152"
    },
    
    {
        "parent":"IRItSqVLTuwDz1ADUoF_25271_1406233152",
        "text":"resistance energy electronic",
        "id":"J3RkmjJ2ByEFqWPlha9_25271_1406233152"
    },
    
    {
        "parent":"IRItSqVLTuwDz1ADUoF_25271_1406233152",
        "text":"resistance resistance fusion",
        "id":"JfPGznd5wpRcl0lYy7n_25271_1406233152"
    },
    
    {
        "parent":"IoraTUPsSNQIhrEEEdr_25271_1406233152",
        "text":"field resistance resistance field",
        "id":"JrhWWWam1W6laqLufVT_25271_1406233152"
    },
    
    {
        "parent":"jWMs9bkriLmELfieoBr_25271_1406233152",
        "text":"resistance electronic electronic",
        "id":"JCPFtfDW6XRRxt1FLTb_25271_1406233152"
    },
    
    {
        "parent":"jWMs9bkriLmELfieoBr_25271_1406233152",
        "text":"electronic resistance resistance current",
        "id":"JPmQAaUVdUMYhXALw3v_25271_1406233152"
    },
    
    {
        "parent":"jWMs9bkriLmELfieoBr_25271_1406233152",
        "text":"Chapter current current fusion current",
        "id":"JW0ce9xlBZBnBcfoygF_25271_1406233152"
    },
    
    {
        "parent":"JW0ce9xlBZBnBcfoygF_25271_1406233152",
        "text":"capacity resistance resistance electronic",
        "id":"K8coNqbT8wFupXom6Ot_25271_1406233152"
    },
    
    {
        "parent":"JW0ce9xlBZBnBcfoygF_25271_1406233152",
        "text":"current electronic capacity",
        "id":"KjKxkpoSzmygUlDP9f3_25271_1406233152"
    },
    
    {
        "parent":"JW0ce9xlBZBnBcfoygF_25271_1406233152",
        "text":"Chapter capacity energy capacity",
        "id":"KpuVyd4JSy1CG7Oqzzb_25271_1406233152"
    },
    
    {
        "parent":"KpuVyd4JSy1CG7Oqzzb_25271_1406233152",
        "text":"Chapter electronic electronic electronic capacity",
        "id":"Kvb7FhqvFEkngm6cLap_25271_1406233152"
    },
    
    {
        "parent":"Kvb7FhqvFEkngm6cLap_25271_1406233152",
        "text":"electronic field electronic electronic",
        "id":"KGQBo2X9L8gcPs97sRz_25271_1406233152"
    },
    
    {
        "parent":"Kvb7FhqvFEkngm6cLap_25271_1406233152",
        "text":"capacity current fusion current",
        "id":"KSRgENXX6W6FnXBO7pT_25271_1406233152"
    },
    
    {
        "parent":"Kvb7FhqvFEkngm6cLap_25271_1406233152",
        "text":"field fusion energy",
        "id":"L4S8VTQs8E0L0948xcR_25271_1406233152"
    },
    
    {
        "parent":"Kvb7FhqvFEkngm6cLap_25271_1406233152",
        "text":"current electronic resistance",
        "id":"Lg4fTy6tBxKogpVgzPH_25271_1406233152"
    },
    
    {
        "parent":"KpuVyd4JSy1CG7Oqzzb_25271_1406233152",
        "text":"Chapter resistance energy resistance current",
        "id":"LlNB5FrOxcVAJO7FbYB_25271_1406233152"
    },
    
    {
        "parent":"LlNB5FrOxcVAJO7FbYB_25271_1406233152",
        "text":"resistance energy field resistance",
        "id":"LxroLK2PdsonPudrNMB_25271_1406233152"
    },
    
    {
        "parent":"LlNB5FrOxcVAJO7FbYB_25271_1406233152",
        "text":"field fusion energy",
        "id":"LJckDg5MSrQAWc72jCx_25271_1406233152"
    },
    
    {
        "parent":"LlNB5FrOxcVAJO7FbYB_25271_1406233152",
        "text":"capacity capacity current electronic",
        "id":"LUx2OHRH3pZ3DeJsAVP_25271_1406233152"
    },
    
    {
        "parent":"LlNB5FrOxcVAJO7FbYB_25271_1406233152",
        "text":"current field current",
        "id":"M60zei1bCmzYOJ6OSad_25271_1406233152"
    },
    
    {
        "parent":"LlNB5FrOxcVAJO7FbYB_25271_1406233152",
        "text":"field energy capacity fusion",
        "id":"MhxeIVafjS3lTnoNzWh_25271_1406233152"
    },
    
    {
        "parent":"LlNB5FrOxcVAJO7FbYB_25271_1406233152",
        "text":"current current field",
        "id":"MsUSZ540Xv0DpTWcwyB_25271_1406233152"
    },
    
    {
        "parent":"LlNB5FrOxcVAJO7FbYB_25271_1406233152",
        "text":"energy resistance electronic energy",
        "id":"MFnrYBhvcyDSRuDbvwJ_25271_1406233152"
    },
    
    {
        "parent":"KpuVyd4JSy1CG7Oqzzb_25271_1406233152",
        "text":"field energy current field",
        "id":"MS4ullgB50jBoOVq3Nn_25271_1406233152"
    },
    
    {
        "parent":"KpuVyd4JSy1CG7Oqzzb_25271_1406233152",
        "text":"electronic resistance capacity resistance",
        "id":"N49yJatbCNoicygzIjf_25271_1406233152"
    },
    
    {
        "parent":"KpuVyd4JSy1CG7Oqzzb_25271_1406233152",
        "text":"Chapter resistance electronic capacity",
        "id":"N9Zp5IFmvuo1vWhQWM9_25271_1406233152"
    },
    
    {
        "parent":"N9Zp5IFmvuo1vWhQWM9_25271_1406233152",
        "text":"electronic resistance capacity field",
        "id":"NlsVviOR4qYWHqFde0x_25271_1406233152"
    },
    
    {
        "parent":"N9Zp5IFmvuo1vWhQWM9_25271_1406233152",
        "text":"energy current resistance capacity",
        "id":"Nx7Md3Ko8cJT5uJcDZL_25271_1406233152"
    },
    
    {
        "parent":"N9Zp5IFmvuo1vWhQWM9_25271_1406233152",
        "text":"energy capacity energy resistance",
        "id":"NIt7pw7pkT3eXzkyd0Z_25271_1406233152"
    },
    
    {
        "parent":"KpuVyd4JSy1CG7Oqzzb_25271_1406233152",
        "text":"fusion electronic energy resistance",
        "id":"NU9RaiQhtNkQSJlju81_25271_1406233152"
    },
    
    {
        "parent":"KpuVyd4JSy1CG7Oqzzb_25271_1406233152",
        "text":"capacity energy energy",
        "id":"O5T6Z7XBJyk1w1hLU4N_25271_1406233152"
    },
    
    {
        "parent":"KpuVyd4JSy1CG7Oqzzb_25271_1406233152",
        "text":"electronic fusion field capacity",
        "id":"Ohlamm3azavxhLHDQEF_25271_1406233152"
    },
    
    {
        "parent":"KpuVyd4JSy1CG7Oqzzb_25271_1406233152",
        "text":"energy electronic energy",
        "id":"Ot3NaaznNdjOK1FaYTv_25271_1406233152"
    },
    
    {
        "parent":"KpuVyd4JSy1CG7Oqzzb_25271_1406233152",
        "text":"energy current resistance",
        "id":"OERF6oKcURAQGdtKa2t_25271_1406233152"
    },
    
    {
        "parent":"KpuVyd4JSy1CG7Oqzzb_25271_1406233152",
        "text":"resistance current field",
        "id":"OQyBRwkMJFW5F3u9co9_25271_1406233152"
    },
    
    {
        "parent":"JW0ce9xlBZBnBcfoygF_25271_1406233152",
        "text":"Chapter current fusion current",
        "id":"OWqYi6VpJdDnGzr7zGN_25271_1406233152"
    },
    
    {
        "parent":"OWqYi6VpJdDnGzr7zGN_25271_1406233152",
        "text":"energy energy current electronic",
        "id":"P82FUORnEqvSbtAuz8l_25271_1406233152"
    },
    
    {
        "parent":"OWqYi6VpJdDnGzr7zGN_25271_1406233152",
        "text":"resistance energy resistance capacity",
        "id":"PkpmKUP8YavtY6rwdup_25271_1406233152"
    },
    
    {
        "parent":"OWqYi6VpJdDnGzr7zGN_25271_1406233152",
        "text":"field current resistance energy",
        "id":"PwcOGtgyK0FfMWgNSa5_25271_1406233152"
    },
    
    {
        "parent":"OWqYi6VpJdDnGzr7zGN_25271_1406233152",
        "text":"Chapter capacity energy resistance energy",
        "id":"PC2F31sJCHEZ6ki56CZ_25271_1406233152"
    },
    
    {
        "parent":"PC2F31sJCHEZ6ki56CZ_25271_1406233152",
        "text":"resistance field electronic energy",
        "id":"POdBAgV35Onjz1tc5KV_25271_1406233152"
    },
    
    {
        "parent":"PC2F31sJCHEZ6ki56CZ_25271_1406233152",
        "text":"field capacity capacity",
        "id":"PZRCgGnLrXTJInyCsNz_25271_1406233152"
    },
    
    {
        "parent":"PC2F31sJCHEZ6ki56CZ_25271_1406233152",
        "text":"field capacity resistance energy",
        "id":"QaWO3e3xC1HA1iBAmD7_25271_1406233152"
    },
    
    {
        "parent":"OWqYi6VpJdDnGzr7zGN_25271_1406233152",
        "text":"Chapter energy energy energy current",
        "id":"QgYbIhTsFrUXAWj8v5v_25271_1406233152"
    },
    
    {
        "parent":"QgYbIhTsFrUXAWj8v5v_25271_1406233152",
        "text":"current energy electronic",
        "id":"Qt2045TP9ODS2BGrAbv_25271_1406233152"
    },
    
    {
        "parent":"QgYbIhTsFrUXAWj8v5v_25271_1406233152",
        "text":"resistance resistance current",
        "id":"QFEQk6yPwb8Zoo5QTJf_25271_1406233152"
    },
    
    {
        "parent":"QgYbIhTsFrUXAWj8v5v_25271_1406233152",
        "text":"electronic energy fusion",
        "id":"QRhaXP5Ut6cn4ke9aSJ_25271_1406233152"
    },
    
    {
        "parent":"QgYbIhTsFrUXAWj8v5v_25271_1406233152",
        "text":"capacity fusion fusion fusion",
        "id":"R2ULDyPdtrBx6kki1s5_25271_1406233152"
    },
    
    {
        "parent":"QgYbIhTsFrUXAWj8v5v_25271_1406233152",
        "text":"current electronic field current",
        "id":"Rfkby238zWmkEL6EzSx_25271_1406233152"
    },
    
    {
        "parent":"OWqYi6VpJdDnGzr7zGN_25271_1406233152",
        "text":"resistance field energy energy",
        "id":"Rs1dUM2eso23c5oT89b_25271_1406233152"
    },
    
    {
        "parent":"OWqYi6VpJdDnGzr7zGN_25271_1406233152",
        "text":"Chapter electronic field field resistance",
        "id":"RxH01aEATGdxEXHnNh7_25271_1406233152"
    },
    
    {
        "parent":"RxH01aEATGdxEXHnNh7_25271_1406233152",
        "text":"resistance field current",
        "id":"RJJ8khJjYOtpDd7yMtX_25271_1406233152"
    },
    
    {
        "parent":"RxH01aEATGdxEXHnNh7_25271_1406233152",
        "text":"field resistance fusion",
        "id":"RUVfhVZlrId2TtYGP6N_25271_1406233152"
    },
    
    {
        "parent":"RxH01aEATGdxEXHnNh7_25271_1406233152",
        "text":"energy resistance electronic",
        "id":"S6i3wKqinIVObixwIMx_25271_1406233152"
    },
    
    {
        "parent":"RxH01aEATGdxEXHnNh7_25271_1406233152",
        "text":"resistance energy field",
        "id":"Si94y1AGDW5i0EgIktb_25271_1406233152"
    },
    
    {
        "parent":"OWqYi6VpJdDnGzr7zGN_25271_1406233152",
        "text":"Chapter field energy energy electronic",
        "id":"SnP3EL4KL8kpxcyQKPL_25271_1406233152"
    },
    
    {
        "parent":"SnP3EL4KL8kpxcyQKPL_25271_1406233152",
        "text":"capacity capacity resistance",
        "id":"tbAayZVCQh1VKGfPX_25271_1406233153"
    },
    
    {
        "parent":"SnP3EL4KL8kpxcyQKPL_25271_1406233152",
        "text":"energy energy electronic electronic",
        "id":"bIEDcGicZvZf2w4uf7_25271_1406233153"
    },
    
    {
        "parent":"SnP3EL4KL8kpxcyQKPL_25271_1406233152",
        "text":"electronic electronic energy electronic",
        "id":"mWrDxRX57IEYJkkCL7_25271_1406233153"
    },
    
    {
        "parent":"SnP3EL4KL8kpxcyQKPL_25271_1406233152",
        "text":"resistance resistance energy energy",
        "id":"ylLWoHm7Z8YYFORFgB_25271_1406233153"
    },
    
    {
        "parent":"JW0ce9xlBZBnBcfoygF_25271_1406233152",
        "text":"Chapter current resistance resistance electronic",
        "id":"Eelnk9GNqTU3RLtNNT_25271_1406233153"
    },
    
    {
        "parent":"Eelnk9GNqTU3RLtNNT_25271_1406233153",
        "text":"Chapter electronic current resistance current",
        "id":"JQLokUMqg9jzU9Ih9v_25271_1406233153"
    },
    
    {
        "parent":"JQLokUMqg9jzU9Ih9v_25271_1406233153",
        "text":"electronic energy energy",
        "id":"ViBLe8DzYhchYzWsuJ_25271_1406233153"
    },
    
    {
        "parent":"JQLokUMqg9jzU9Ih9v_25271_1406233153",
        "text":"current capacity current",
        "id":"16zxQCjRAFmjUPiP1yp_25271_1406233153"
    },
    
    {
        "parent":"JQLokUMqg9jzU9Ih9v_25271_1406233153",
        "text":"field field fusion current",
        "id":"1j13OscPscHq421Bclj_25271_1406233153"
    },
    
    {
        "parent":"JQLokUMqg9jzU9Ih9v_25271_1406233153",
        "text":"field fusion current",
        "id":"1uMcGj7uN6dgepUPtpT_25271_1406233153"
    },
    
    {
        "parent":"JQLokUMqg9jzU9Ih9v_25271_1406233153",
        "text":"current electronic field current",
        "id":"1Gi29ANJMZs74mef8fn_25271_1406233153"
    },
    
    {
        "parent":"JQLokUMqg9jzU9Ih9v_25271_1406233153",
        "text":"current current resistance energy",
        "id":"1Rxici3kos4cdMZZBpT_25271_1406233153"
    },
    
    {
        "parent":"Eelnk9GNqTU3RLtNNT_25271_1406233153",
        "text":"energy electronic energy energy",
        "id":"22JPaC2Ld9V5BpQpaw1_25271_1406233153"
    },
    
    {
        "parent":"Eelnk9GNqTU3RLtNNT_25271_1406233153",
        "text":"Chapter resistance resistance electronic",
        "id":"28sklnVhrcRLQ64eJIl_25271_1406233153"
    },
    
    {
        "parent":"28sklnVhrcRLQ64eJIl_25271_1406233153",
        "text":"current energy resistance energy",
        "id":"2jTKHBpJf6SoqOvboAh_25271_1406233153"
    },
    
    {
        "parent":"28sklnVhrcRLQ64eJIl_25271_1406233153",
        "text":"capacity resistance resistance",
        "id":"2vfVVpfz9pqgxB560y5_25271_1406233153"
    },
    
    {
        "parent":"28sklnVhrcRLQ64eJIl_25271_1406233153",
        "text":"resistance capacity current field",
        "id":"2GjEFARpA8OHqMazzJ7_25271_1406233153"
    },
    
    {
        "parent":"28sklnVhrcRLQ64eJIl_25271_1406233153",
        "text":"field current electronic",
        "id":"2SlMYHW8Fh4zp1AKyVX_25271_1406233153"
    },
    
    {
        "parent":"28sklnVhrcRLQ64eJIl_25271_1406233153",
        "text":"resistance field energy",
        "id":"34AIClQPYyTRZAF31y9_25271_1406233153"
    },
    
    {
        "parent":"28sklnVhrcRLQ64eJIl_25271_1406233153",
        "text":"current resistance electronic",
        "id":"3gGD1wwfdYd521YLJ0B_25271_1406233153"
    },
    
    {
        "parent":"28sklnVhrcRLQ64eJIl_25271_1406233153",
        "text":"fusion current resistance current",
        "id":"3tI0UUwFF7yUk3IdbbP_25271_1406233153"
    },
    
    {
        "parent":"Eelnk9GNqTU3RLtNNT_25271_1406233153",
        "text":"Chapter fusion fusion resistance",
        "id":"3A375BMOfxhvtmS2VQR_25271_1406233153"
    },
    
    {
        "parent":"3A375BMOfxhvtmS2VQR_25271_1406233153",
        "text":"capacity capacity resistance capacity",
        "id":"3MxM8uFlfDv3vJvrxbr_25271_1406233153"
    },
    
    {
        "parent":"3A375BMOfxhvtmS2VQR_25271_1406233153",
        "text":"fusion current electronic",
        "id":"3YRWUyeEswN6AeqM2HL_25271_1406233153"
    },
    
    {
        "parent":"3A375BMOfxhvtmS2VQR_25271_1406233153",
        "text":"electronic fusion current",
        "id":"4barDUSkgbC7bjoYskV_25271_1406233153"
    },
    
    {
        "parent":"3A375BMOfxhvtmS2VQR_25271_1406233153",
        "text":"electronic field fusion current",
        "id":"4n3lIdQ3BxigxL4VV9n_25271_1406233153"
    },
    
    {
        "parent":"3A375BMOfxhvtmS2VQR_25271_1406233153",
        "text":"current electronic resistance",
        "id":"4zhekbqexiPpPWb1zAl_25271_1406233153"
    },
    
    {
        "parent":"3A375BMOfxhvtmS2VQR_25271_1406233153",
        "text":"energy resistance resistance",
        "id":"4LdUuxYE2VyUgzKwKEp_25271_1406233153"
    },
    
    {
        "parent":"3A375BMOfxhvtmS2VQR_25271_1406233153",
        "text":"fusion electronic resistance",
        "id":"4WJwXuNbmUK82Q4iEff_25271_1406233153"
    },
    
    {
        "parent":"Eelnk9GNqTU3RLtNNT_25271_1406233153",
        "text":"resistance fusion field",
        "id":"59d8YHlbZuFwMOJuroB_25271_1406233153"
    },
    
    {
        "parent":"Eelnk9GNqTU3RLtNNT_25271_1406233153",
        "text":"Chapter energy current capacity",
        "id":"5fkONRafk2DO8MghqWl_25271_1406233153"
    },
    
    {
        "parent":"5fkONRafk2DO8MghqWl_25271_1406233153",
        "text":"electronic capacity current",
        "id":"5r3eBkOKSbosxmeaNWx_25271_1406233153"
    },
    
    {
        "parent":"5fkONRafk2DO8MghqWl_25271_1406233153",
        "text":"capacity capacity current energy",
        "id":"5CmTL6g8FDeLW0Soh4B_25271_1406233153"
    },
    
    {
        "parent":"5fkONRafk2DO8MghqWl_25271_1406233153",
        "text":"energy resistance current electronic",
        "id":"5NEFRPUbnWypNzzPT4R_25271_1406233153"
    },
    
    {
        "parent":"5fkONRafk2DO8MghqWl_25271_1406233153",
        "text":"current field resistance field",
        "id":"5ZtNQ5hez1be5PmfDDH_25271_1406233153"
    },
    
    {
        "parent":"5fkONRafk2DO8MghqWl_25271_1406233153",
        "text":"field field electronic capacity",
        "id":"6bi5MZbt2tzw9na6lfX_25271_1406233153"
    },
    
    {
        "parent":"5fkONRafk2DO8MghqWl_25271_1406233153",
        "text":"fusion energy energy",
        "id":"6mFX3tWWm0AqJzH936V_25271_1406233153"
    },
    
    {
        "parent":"5fkONRafk2DO8MghqWl_25271_1406233153",
        "text":"energy electronic current energy",
        "id":"6ybZx6uT1NSUDc0ctb3_25271_1406233153"
    },
    
    {
        "parent":"5fkONRafk2DO8MghqWl_25271_1406233153",
        "text":"resistance field current",
        "id":"6LaRms6Rm6xbd5NWMwx_25271_1406233153"
    },
    
    {
        "parent":"5fkONRafk2DO8MghqWl_25271_1406233153",
        "text":"capacity field fusion",
        "id":"6WPi3xiZ44aRtNSEG2t_25271_1406233153"
    },
    
    {
        "parent":"5fkONRafk2DO8MghqWl_25271_1406233153",
        "text":"electronic current current resistance",
        "id":"793aFuT9ZPI0LYYKktr_25271_1406233153"
    },
    
    {
        "parent":"Eelnk9GNqTU3RLtNNT_25271_1406233153",
        "text":"Chapter capacity fusion resistance current",
        "id":"7fzb7HbVJgtn0vPVHq1_25271_1406233153"
    },
    
    {
        "parent":"7fzb7HbVJgtn0vPVHq1_25271_1406233153",
        "text":"resistance energy resistance capacity",
        "id":"7suTRZOkV0fbHfJ3AdP_25271_1406233153"
    },
    
    {
        "parent":"7fzb7HbVJgtn0vPVHq1_25271_1406233153",
        "text":"current resistance field",
        "id":"7Ez8ety6Lb5mgh5EbN7_25271_1406233153"
    },
    
    {
        "parent":"7fzb7HbVJgtn0vPVHq1_25271_1406233153",
        "text":"current capacity resistance current",
        "id":"7PRxmdNgvczTiRM15vj_25271_1406233153"
    },
    
    {
        "parent":"7fzb7HbVJgtn0vPVHq1_25271_1406233153",
        "text":"energy field electronic",
        "id":"81NauU19Dj1er7njso9_25271_1406233153"
    },
    
    {
        "parent":"7fzb7HbVJgtn0vPVHq1_25271_1406233153",
        "text":"field field energy current",
        "id":"8e4pcfsBnxusG8nFiBr_25271_1406233153"
    },
    
    {
        "parent":"Eelnk9GNqTU3RLtNNT_25271_1406233153",
        "text":"resistance current resistance electronic",
        "id":"8p8xX6NRa509GFsqofL_25271_1406233153"
    },
    
    {
        "parent":"Eelnk9GNqTU3RLtNNT_25271_1406233153",
        "text":"Chapter current resistance current fusion",
        "id":"8uJ4V5LBHLITFBTT0tz_25271_1406233153"
    },
    
    {
        "parent":"8uJ4V5LBHLITFBTT0tz_25271_1406233153",
        "text":"fusion current fusion fusion",
        "id":"8GkzxsPRX4xL6Q3CeGt_25271_1406233153"
    },
    
    {
        "parent":"8uJ4V5LBHLITFBTT0tz_25271_1406233153",
        "text":"fusion capacity energy",
        "id":"8T1oTRXg9C9QAumd1It_25271_1406233153"
    },
    
    {
        "parent":"8uJ4V5LBHLITFBTT0tz_25271_1406233153",
        "text":"capacity current fusion current",
        "id":"95LAlEVVaCI10Yz40wN_25271_1406233153"
    },
    
    {
        "parent":"8uJ4V5LBHLITFBTT0tz_25271_1406233153",
        "text":"current resistance current resistance",
        "id":"9hLCBplBuInAos2Pnnb_25271_1406233153"
    },
    
    {
        "parent":"Eelnk9GNqTU3RLtNNT_25271_1406233153",
        "text":"resistance field electronic electronic",
        "id":"9u8jrvjmOsncb4TR1Jf_25271_1406233153"
    },
    
    {
        "parent":"Eelnk9GNqTU3RLtNNT_25271_1406233153",
        "text":"electronic current field",
        "id":"9GLMIwzucx3cHTibCYV_25271_1406233153"
    },
    
    {
        "parent":"Eelnk9GNqTU3RLtNNT_25271_1406233153",
        "text":"Chapter electronic field capacity resistance",
        "id":"9NgK92xJyrwpE2babKh_25271_1406233153"
    },
    
    {
        "parent":"9NgK92xJyrwpE2babKh_25271_1406233153",
        "text":"resistance electronic resistance capacity",
        "id":"9YjcRcXlVKz4b9iNbvr_25271_1406233153"
    },
    
    {
        "parent":"9NgK92xJyrwpE2babKh_25271_1406233153",
        "text":"energy field electronic",
        "id":"a9Hu8nseB5HeSHP7pPH_25271_1406233153"
    },
    
    {
        "parent":"9NgK92xJyrwpE2babKh_25271_1406233153",
        "text":"current electronic electronic current",
        "id":"alkENrs8fCZ8NlVYJVL_25271_1406233153"
    },
    
    {
        "parent":"9NgK92xJyrwpE2babKh_25271_1406233153",
        "text":"electronic capacity energy",
        "id":"axciPJdDxyjvNJE5Dkl_25271_1406233153"
    },
    
    {
        "parent":"9NgK92xJyrwpE2babKh_25271_1406233153",
        "text":"resistance resistance field",
        "id":"aIQwwty3zBTz0LJ9LBD_25271_1406233153"
    },
    
    {
        "parent":"9NgK92xJyrwpE2babKh_25271_1406233153",
        "text":"electronic electronic field",
        "id":"aUsE9RdqQCTjD1ROhwt_25271_1406233153"
    },
    
    {
        "parent":"9NgK92xJyrwpE2babKh_25271_1406233153",
        "text":"resistance energy field electronic",
        "id":"b5Ge9Rxo2R2mj2GqENP_25271_1406233153"
    },
    
    {
        "parent":"9NgK92xJyrwpE2babKh_25271_1406233153",
        "text":"field energy resistance fusion",
        "id":"bhu665IdavjofeuZPWN_25271_1406233153"
    },
    
    {
        "parent":"JW0ce9xlBZBnBcfoygF_25271_1406233152",
        "text":"Chapter electronic current electronic",
        "id":"bnwWNvC3XfWbeCa2j3H_25271_1406233153"
    },
    
    {
        "parent":"bnwWNvC3XfWbeCa2j3H_25271_1406233153",
        "text":"Chapter resistance current electronic resistance",
        "id":"btUz2fgEEwml63fzcyt_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"fusion electronic current resistance",
        "id":"bFjtkqmElzFoYDKOIAF_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"current energy electronic capacity",
        "id":"bQQLQ46P4NjFek1II4F_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"resistance energy resistance field",
        "id":"c2CkIAKTLuWLw3UevCx_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"energy capacity electronic",
        "id":"cdXFV37UYbg7o8vA4DL_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"electronic current fusion",
        "id":"cpg52Nn4IcKEqJbWYlX_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"energy energy capacity current",
        "id":"cB1dUEhK36guB75bfqx_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"resistance electronic field electronic",
        "id":"cMfDW04vWWE3vPSmFEt_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"fusion fusion electronic resistance",
        "id":"cXOPuFC1LiOZiC62wgh_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"capacity resistance fusion fusion",
        "id":"d9fcPcLXbGxsAWyMmWZ_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"field electronic current resistance",
        "id":"dkN8lR7eWCmC1EOBE8V_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"resistance resistance energy",
        "id":"dwI8twK130D3YSqYJjP_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"resistance current electronic resistance",
        "id":"dI0XBWIA8QeR8P6D9vj_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"current resistance electronic",
        "id":"dTtR0wgXG4ET9hv491L_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"energy resistance electronic current",
        "id":"e5tTggGE0akswKYPvS9_25271_1406233153"
    },
    
    {
        "parent":"btUz2fgEEwml63fzcyt_25271_1406233153",
        "text":"energy resistance capacity capacity",
        "id":"eirv3B6oh2CWKAOJfNL_25271_1406233153"
    },
    
    {
        "parent":"bnwWNvC3XfWbeCa2j3H_25271_1406233153",
        "text":"electronic capacity energy",
        "id":"euUu3N3hRUnsjxuZLfb_25271_1406233153"
    },
    
    {
        "parent":"bnwWNvC3XfWbeCa2j3H_25271_1406233153",
        "text":"electronic energy fusion energy",
        "id":"eH6TDozx4lvcbYDB51D_25271_1406233153"
    },
    
    {
        "parent":"bnwWNvC3XfWbeCa2j3H_25271_1406233153",
        "text":"Chapter fusion current current",
        "id":"eNqWMpv9heVE2TPe1vr_25271_1406233153"
    },
    
    {
        "parent":"eNqWMpv9heVE2TPe1vr_25271_1406233153",
        "text":"electronic resistance resistance resistance",
        "id":"f0u0Iurd7CKvOlvNzzP_25271_1406233153"
    },
    
    {
        "parent":"eNqWMpv9heVE2TPe1vr_25271_1406233153",
        "text":"energy field electronic capacity",
        "id":"fcIWm8lUqUzOoUA62c1_25271_1406233153"
    },
    
    {
        "parent":"eNqWMpv9heVE2TPe1vr_25271_1406233153",
        "text":"fusion electronic current",
        "id":"foILBxTT56bKII4dDNL_25271_1406233153"
    },
    
    {
        "parent":"eNqWMpv9heVE2TPe1vr_25271_1406233153",
        "text":"electronic resistance energy",
        "id":"fBYcRtWvNPsMZ7pD8Od_25271_1406233153"
    },
    
    {
        "parent":"eNqWMpv9heVE2TPe1vr_25271_1406233153",
        "text":"resistance fusion current fusion",
        "id":"fOBT8Q4kROcqzBNBvix_25271_1406233153"
    },
    
    {
        "parent":"eNqWMpv9heVE2TPe1vr_25271_1406233153",
        "text":"energy current resistance",
        "id":"g0ReN9IrwU8ZhwRbuo1_25271_1406233153"
    },
    
    {
        "parent":"jWMs9bkriLmELfieoBr_25271_1406233152",
        "text":"electronic fusion resistance resistance",
        "id":"gcHcMKyjpB0jOuCahTr_25271_1406233153"
    },
    
    {
        "parent":"jWMs9bkriLmELfieoBr_25271_1406233152",
        "text":"Chapter capacity energy resistance current",
        "id":"gj918dwZCWB4RtAwq77_25271_1406233153"
    },
    
    {
        "parent":"gj918dwZCWB4RtAwq77_25271_1406233153",
        "text":"resistance electronic energy capacity",
        "id":"gv029uHnT9KyGPjI1NL_25271_1406233153"
    },
    
    {
        "parent":"gj918dwZCWB4RtAwq77_25271_1406233153",
        "text":"Chapter electronic fusion current",
        "id":"gAR8y45MPh64mhiPPGx_25271_1406233153"
    },
    
    {
        "parent":"gAR8y45MPh64mhiPPGx_25271_1406233153",
        "text":"Chapter field energy capacity energy",
        "id":"gGVshQ3zlm8gLoVmDrX_25271_1406233153"
    },
    
    {
        "parent":"gGVshQ3zlm8gLoVmDrX_25271_1406233153",
        "text":"capacity energy resistance field",
        "id":"gS5TcNnXp1oRyfPmAbD_25271_1406233153"
    },
    
    {
        "parent":"gGVshQ3zlm8gLoVmDrX_25271_1406233153",
        "text":"field electronic fusion current",
        "id":"h4mHTt5ZNrKPFUQqTVD_25271_1406233153"
    },
    
    {
        "parent":"gGVshQ3zlm8gLoVmDrX_25271_1406233153",
        "text":"resistance electronic current",
        "id":"hgQJVlnpLPNuxfuUdyh_25271_1406233153"
    },
    
    {
        "parent":"gGVshQ3zlm8gLoVmDrX_25271_1406233153",
        "text":"energy current capacity fusion",
        "id":"hsXHmcnloLoQS4MPJbX_25271_1406233153"
    },
    
    {
        "parent":"gGVshQ3zlm8gLoVmDrX_25271_1406233153",
        "text":"resistance energy electronic fusion",
        "id":"hEcXoTCW0e0W1vyAcmt_25271_1406233153"
    },
    
    {
        "parent":"gj918dwZCWB4RtAwq77_25271_1406233153",
        "text":"Chapter field field resistance",
        "id":"hJSjuCvT5I5an1RNl17_25271_1406233153"
    },
    
    {
        "parent":"hJSjuCvT5I5an1RNl17_25271_1406233153",
        "text":"current resistance capacity",
        "id":"hWEaZ6qbvX6ngW1MpIB_25271_1406233153"
    },
    
    {
        "parent":"hJSjuCvT5I5an1RNl17_25271_1406233153",
        "text":"Chapter energy electronic electronic electronic",
        "id":"i39yqi7QdFGQkqU2uXf_25271_1406233153"
    },
    
    {
        "parent":"i39yqi7QdFGQkqU2uXf_25271_1406233153",
        "text":"field resistance field current",
        "id":"ifqA7iHAi06rvLUKzVT_25271_1406233153"
    },
    
    {
        "parent":"i39yqi7QdFGQkqU2uXf_25271_1406233153",
        "text":"resistance fusion electronic",
        "id":"iqTtvSfXPewtwejbzsl_25271_1406233153"
    },
    
    {
        "parent":"i39yqi7QdFGQkqU2uXf_25271_1406233153",
        "text":"electronic field current current",
        "id":"iCdyGjqKYuu32eWGz3H_25271_1406233153"
    },
    
    {
        "parent":"i39yqi7QdFGQkqU2uXf_25271_1406233153",
        "text":"current electronic fusion",
        "id":"iOT80HlV7BKm9PhqMFP_25271_1406233153"
    },
    
    {
        "parent":"i39yqi7QdFGQkqU2uXf_25271_1406233153",
        "text":"resistance energy current capacity",
        "id":"j0gzgwnZ5kE0CFPbY3v_25271_1406233153"
    },
    
    {
        "parent":"i39yqi7QdFGQkqU2uXf_25271_1406233153",
        "text":"fusion resistance resistance fusion",
        "id":"jbl823sEdGgXKyTeAb7_25271_1406233153"
    },
    
    {
        "parent":"i39yqi7QdFGQkqU2uXf_25271_1406233153",
        "text":"capacity energy resistance",
        "id":"jmVzCKco5sNFTp4L0cN_25271_1406233153"
    },
    
    {
        "parent":"hJSjuCvT5I5an1RNl17_25271_1406233153",
        "text":"Chapter resistance current electronic capacity",
        "id":"jsKzXWVKgxySY57tbJ7_25271_1406233153"
    },
    
    {
        "parent":"jsKzXWVKgxySY57tbJ7_25271_1406233153",
        "text":"capacity energy capacity",
        "id":"jEkbxicFqHR4SdkqyOd_25271_1406233153"
    },
    
    {
        "parent":"jsKzXWVKgxySY57tbJ7_25271_1406233153",
        "text":"capacity current energy",
        "id":"jQbPzzYaIDbrSB2xscN_25271_1406233153"
    },
    
    {
        "parent":"hJSjuCvT5I5an1RNl17_25271_1406233153",
        "text":"fusion resistance electronic fusion",
        "id":"k1FlZa7FhzMn45pTJrb_25271_1406233153"
    },
    
    {
        "parent":"hJSjuCvT5I5an1RNl17_25271_1406233153",
        "text":"Chapter fusion field fusion current",
        "id":"k7NeOEOqi1OhtIWkudz_25271_1406233153"
    },
    
    {
        "parent":"k7NeOEOqi1OhtIWkudz_25271_1406233153",
        "text":"current energy energy capacity",
        "id":"kjOx6qqkFxPDdgnWqtP_25271_1406233153"
    },
    
    {
        "parent":"k7NeOEOqi1OhtIWkudz_25271_1406233153",
        "text":"resistance field electronic",
        "id":"kvtAOwdzpdEcF0rzBHH_25271_1406233153"
    },
    
    {
        "parent":"k7NeOEOqi1OhtIWkudz_25271_1406233153",
        "text":"electronic capacity field",
        "id":"kHR7FXE9qzSkGlhaj0l_25271_1406233153"
    },
    
    {
        "parent":"k7NeOEOqi1OhtIWkudz_25271_1406233153",
        "text":"capacity energy fusion",
        "id":"kTHvGedqF4QVkF1qCZ3_25271_1406233153"
    },
    
    {
        "parent":"k7NeOEOqi1OhtIWkudz_25271_1406233153",
        "text":"energy field capacity resistance",
        "id":"l5vaC7wy6P4kdaQm2Tn_25271_1406233153"
    },
    
    {
        "parent":"k7NeOEOqi1OhtIWkudz_25271_1406233153",
        "text":"field field resistance current",
        "id":"lgVKWZybd6QqzbiJEOJ_25271_1406233153"
    },
    
    {
        "parent":"k7NeOEOqi1OhtIWkudz_25271_1406233153",
        "text":"current current current resistance",
        "id":"ltHpr8ALXrO0ppt4Yhz_25271_1406233153"
    },
    
    {
        "parent":"k7NeOEOqi1OhtIWkudz_25271_1406233153",
        "text":"capacity electronic capacity",
        "id":"lGdXx3gE2GydYS3fqJX_25271_1406233153"
    },
    
    {
        "parent":"k7NeOEOqi1OhtIWkudz_25271_1406233153",
        "text":"energy field energy energy",
        "id":"lSbtILhSfVweEdBjEKB_25271_1406233153"
    },
    
    {
        "parent":"hJSjuCvT5I5an1RNl17_25271_1406233153",
        "text":"Chapter electronic field current resistance",
        "id":"lYAyZR0oGwlNVoEkSTT_25271_1406233153"
    },
    
    {
        "parent":"lYAyZR0oGwlNVoEkSTT_25271_1406233153",
        "text":"fusion energy electronic",
        "id":"maWcOgDDCK3gpDx9J4J_25271_1406233153"
    },
    
    {
        "parent":"gj918dwZCWB4RtAwq77_25271_1406233153",
        "text":"field current current field",
        "id":"mnZgKlzHt7S8b5dJh97_25271_1406233153"
    },
    
    {
        "parent":"gj918dwZCWB4RtAwq77_25271_1406233153",
        "text":"resistance fusion current",
        "id":"mAvBPVnRSsyIGROfYmR_25271_1406233153"
    },
    
    {
        "parent":"#",
        "text":"field fusion resistance resistance",
        "id":"mMoVUU50zCm8aFtuXEB_25271_1406233153"
    },
    
    {
        "parent":"#",
        "text":"resistance capacity field field",
        "id":"mYEhzdJ7eIiGSAx4WK5_25271_1406233153"
    },
    
    {
        "parent":"#",
        "text":"field energy fusion energy",
        "id":"nb4kuHy9mVenC3imMSt_25271_1406233153"
    },
    
    {
        "parent":"#",
        "text":"energy electronic field resistance",
        "id":"nngk3DkZdyeRn8rGAbD_25271_1406233153"
    },
    
    {
        "parent":"#",
        "text":"resistance resistance energy",
        "id":"nyRBFFxxMX05KGBM39T_25271_1406233153"
    },
    
    {
        "parent":"#",
        "text":"Chapter fusion fusion resistance",
        "id":"nEuEHGTKruqorKYVOdr_25271_1406233153"
    },
    
    {
        "parent":"nEuEHGTKruqorKYVOdr_25271_1406233153",
        "text":"current current electronic resistance",
        "id":"nQKqmGhgsoudh21NjMd_25271_1406233153"
    },
    
    {
        "parent":"nEuEHGTKruqorKYVOdr_25271_1406233153",
        "text":"energy energy resistance resistance",
        "id":"o3lNAkSl5qzVd4tIiFr_25271_1406233153"
    },
    
    {
        "parent":"nEuEHGTKruqorKYVOdr_25271_1406233153",
        "text":"energy current capacity electronic",
        "id":"ogfqhgPHw7Lrj2qqz6N_25271_1406233153"
    },
    
    {
        "parent":"#",
        "text":"electronic capacity electronic field",
        "id":"orXq44KNIsoPAgp2pDH_25271_1406233153"
    },
    
    {
        "parent":"#",
        "text":"resistance energy energy",
        "id":"oE4NvBu8Hc7s2rGfrKF_25271_1406233153"
    }
]
ENDCONTENTS
   return OK;
}
1;
__END__

