#!/usr/bin/awk -f
#
# Rearrange the tests in the files for the branch instructions
# (beq-01.S, bge-01.S, ...) to reduce the required memory


function hex2int(hex)
{
    r = 0;
    for(j=3; j<=length(hex); j++) {
        x = index("0123456789abcdef",substr(hex,j,1));
        r = (16*r) + x - 1;
    }
    return r;
}

function reorder_cases()
{
    if (casedone < caseno) {
        printf("RVTEST_SIGBASE(%s, %s)\n", sigreg[casedone], sigtag[casedone]);
    }
    for (i=casedone; i<=caseno; i++) {
        if (length(imm[i]) <= 4) {
            printf("inst_%d:\nTEST_BRANCH_OP(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s,%s)\n", i,
                inst[i], tempreg[i], reg1[i], reg2[i], val1[i], val2[i],
                imm[i], label[i], swreg[i], offset[i], adj[i]);
        }
    }
    casedone = caseno+1;
}


BEGIN {
    FS = ","
    caseno = -1;
    casedone = 1;
}


NR==1, /^RVTEST_CASE/ {
    print
}


/^inst_/ {
    caseno = 0 + substr($1, 6);
}


/^TEST_BRANCH_OP/ {

    gsub(/ /, "");
    gsub(/)/, "");

    inst[caseno] = substr($1, 16);
    tempreg[caseno] = $2;
    reg1[caseno] = $3;
    reg2[caseno] = $4;
    val1[caseno] = $5;
    val2[caseno] = $6;
    imm[caseno] = $7;
    label[caseno] = $8;
    swreg[caseno] = $9;
    offset[caseno] = $10;
    adj[caseno] = $11;
    sigreg[caseno] = cur_sigreg;
    sigtag[caseno] = cur_sigtag;

    histo[imm[caseno]]++;
}


/^RVTEST_SIGBASE/ {
    reorder_cases();

    gsub(/ /, "");
    gsub(/)/, "");
    cur_sigreg = substr($1, 16);
    cur_sigtag = $2;
}


/^RVTEST_CODE_END/ {
    reorder_cases();

    for (dist_s in histo) {
        if (length(dist_s) > 4) {
            max_insns = hex2int(dist_s) / 2;
                # the distance is given in #halfwords, convert to #instructions

            estimate = max_insns;
            for (i=0; i<=caseno; i++) {
                if (imm[i] == dist_s && label[i] == "1b") {

                    estimate += 12; # max instructions per test
                    if (estimate > max_insns) {
                        printf("TEST_BRANCH_BWD_RETURNBLOCK(%s)\n", dist_s);
                        estimate = 12;
                    }

                    printf("inst_%d:\nTEST_BRANCH_BWD_OP(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)\n", i,
                        inst[i], tempreg[i], reg1[i], reg2[i], val1[i], val2[i],
                        imm[i], swreg[i], offset[i], sigtag[i]);
                }
            }

            estimate = 0;
            for (i=0; i<=caseno; i++) {
                if (imm[i] == dist_s && label[i] == "3f") {

                    estimate += 12; # max instructions per test
                    if (estimate > max_insns) {
                        printf("TEST_BRANCH_FWD_RETURNBLOCK(%s)\n", dist_s);
                        estimate = 12;
                    }

                    printf("inst_%d:\nTEST_BRANCH_FWD_OP(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)\n", i,
                        inst[i], tempreg[i], reg1[i], reg2[i], val1[i], val2[i],
                        imm[i], swreg[i], offset[i], sigtag[i]);
                }
            }
            if (estimate>0) {
                printf("TEST_BRANCH_FWD_RETURNBLOCK(%s)\n", dist_s);
            }
        }
    }

    print "#endif"
}


/^RVTEST_CODE_END/, /RVMODEL_DATA_END/ {
    print
}


END {
#    print "==================================================================="
#    for (i in histo) {
#        printf("%s\t%d\n", i, histo[i]);
#    }
}
