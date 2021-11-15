USE housing;
SELECT * FROM housing;

/*
Cleaning Data in SQL Queries
*/

-- Standardize Date Format

UPDATE housing SET SaleDate = str_to_date(SaleDate, "%M %d, %Y");

/* -------------------------------------------------------------------------------------------------------------------------- */

-- Populate Property Address data

DROP TEMPORARY TABLE change_address;
CREATE TEMPORARY TABLE change_address
SELECT a.ParcelID, a.PropertyAddress, b.parcelID_b, b.propertyAddress_b, IFNULL(a.PropertyAddress, b.propertyAddress_b) AS new_address
FROM housing a
INNER JOIN address b
	ON a.ParcelID = b.parcelID_b
	AND a.UniqueID <> b.uniqueID_b
WHERE a.PropertyAddress IS NULL;

-- ADD column add_address as a helper column
ALTER TABLE housing ADD COLUMN add_address text;

-- Update add_address column that has the property address for PropertyAddress column is null
UPDATE housing t1
INNER JOIN change_address t2 ON t1.ParcelID = t2.ParcelID
SET t1.add_address = t2.new_address;

-- ADD add_address column values into PropertyAddress NULL values
UPDATE housing SET PropertyAddress = add_address
WHERE PropertyAddress IS NULL;

-- REMOVED Helper COLUMN
ALTER TABLE housing DROP add_address; 

/* -------------------------------------------------------------------------------------------------------------------------- */

-- Breaking out Address into Individual Columns (Address, City, State) for PropertyAddress
SELECT PropertyAddress from housing;

SELECT
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1 , LENGTH(PropertyAddress)) as Address
FROM housing;

ALTER TABLE housing
ADD PropertySplitAddress TEXT;

UPDATE housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1 );

ALTER TABLE housing
Add PropertySplitCity TEXT;

UPDATE housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1 , LENGTH(PropertyAddress));

SELECT * FROM housing;

/* -------------------------------------------------------------------------------------------------------------------------- */

-- Breaking out Address into Individual Columns (Address, City, State) for OwnerAddress 
SELECT 
  SUBSTRING_INDEX(OwnerAddress, ',', 1) AS owner_address,
  SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS city,
  SUBSTRING_INDEX(OwnerAddress, ',', -1) AS state
FROM housing;

ALTER TABLE housing
ADD OwnerSplitAddress TEXT;

UPDATE housing
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE housing
ADD OwnerSplitCity TEXT;

Update housing
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

ALTER TABLE housing
ADD OwnerSplitState TEXT;

UPDATE housing
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

/* -------------------------------------------------------------------------------------------------------------------------- */

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT SoldAsVacant FROM housing;

SELECT
	SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes' 
		WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END AS yes_no
FROM housing
WHERE SoldAsVacant = 'Y'
	OR SoldAsVacant = 'N';
    
UPDATE housing
SET SoldAsVacant = 
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END;

/* -------------------------------------------------------------------------------------------------------------------------- */

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM housing
-- order by ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

SELECT *
FROM housing;

/* -------------------------------------------------------------------------------------------------------------------------- */

-- Delete Unused Columns

ALTER TABLE housing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress, 
DROP COLUMN SaleDate;

SELECT * FROM housing;

