## 1. Load data into R

# Read in bim file
bim <- read.table("EUR.bim")
colnames(bim) <- c("CHR", "SNP", "CM", "BP", "B.A1", "B.A2")
# Read in QCed SNPs
qc <- read.table("EUR.QC.snplist", header = F, stringsAsFactors = F)
# Read in the GWAS data
height <-
    read.table(gzfile("Height.QC.gz"),
               header = T,
               stringsAsFactors = F, 
               sep="\t")
# Change all alleles to upper case for easy comparison
height$A1 <- toupper(height$A1)
height$A2 <- toupper(height$A2)
bim$B.A1 <- toupper(bim$B.A1)
bim$B.A2 <- toupper(bim$B.A2)

## 2. Identify SNPs that require strand flipping

# Merge summary statistic with target
info <- merge(bim, height, by = c("SNP", "CHR", "BP"))
# Filter QCed SNPs
info <- info[info$SNP %in% qc$V1,]
# Function for finding the complementary allele
complement <- function(x) {
    switch (
        x,
        "A" = "T",
        "C" = "G",
        "T" = "A",
        "G" = "C",
        return(NA)
    )
}
# Get SNPs that have the same alleles across base and target
info.match <- subset(info, A1 == B.A1 & A2 == B.A2)
# Identify SNPs that are complementary between base and target
info$C.A1 <- sapply(info$B.A1, complement)
info$C.A2 <- sapply(info$B.A2, complement)
info.complement <- subset(info, A1 == C.A1 & A2 == C.A2)
# Update the complementary alleles in the bim file
# This allow us to match the allele in subsequent analysis
complement.snps <- bim$SNP %in% info.complement$SNP
bim[complement.snps,]$B.A1 <-
    sapply(bim[complement.snps,]$B.A1, complement)
bim[complement.snps,]$B.A2 <-
    sapply(bim[complement.snps,]$B.A2, complement)

## 3. Identify SNPs that require recoding in the target

# identify SNPs that need recoding
info.recode <- subset(info, A1 == B.A2 & A2 == B.A1)
# Update the recode SNPs
recode.snps <- bim$SNP %in% info.recode$SNP
tmp <- bim[recode.snps,]$B.A1
bim[recode.snps,]$B.A1 <- bim[recode.snps,]$B.A2
bim[recode.snps,]$B.A2 <- tmp

# identify SNPs that need recoding & complement
info.crecode <- subset(info, A1 == C.A2 & A2 == C.A1)
# Update the recode + strand flip SNPs
com.snps <- bim$SNP %in% info.crecode$SNP
tmp <- bim[com.snps,]$B.A1
bim[com.snps,]$B.A1 <- as.character(sapply(bim[com.snps,]$B.A2, complement))
bim[com.snps,]$B.A2 <- as.character(sapply(tmp, complement))

# Output updated bim file
bim$B.A1 <- unlist(bim$B.A1) # ARK, to deal with error using write.table
bim$B.A2 <- unlist(bim$B.A2)
write.table(
    bim,
    "EUR.QC.adj.bim",
    quote = F,
    row.names = F,
    col.names = F,
    sep="\t"
)

## 4. Identify SNPs that have different allele in base and target
mismatch <-
    bim$SNP[!(bim$SNP %in% info.match$SNP |
                  bim$SNP %in% info.complement$SNP | 
                  bim$SNP %in% info.recode$SNP |
                  bim$SNP %in% info.crecode$SNP)]
write.table(
    mismatch,
    "EUR.mismatch",
    quote = F,
    row.names = F,
    col.names = F
)

### ARK, write out recoded SNPs
write.table(
    bim[complement.snps,]$SNP,
    "mismatch_com.snps",
    quote = F,
    row.names = F,
    col.names = F
)
write.table(
    bim[recode.snps,]$SNP,
    "mismatch_recode.snps",
    quote = F,
    row.names = F,
    col.names = F
)


q() # exit R







