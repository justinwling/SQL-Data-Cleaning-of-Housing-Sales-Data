/* Cleaning Data in SQL Queries  */


Select *
From [SQL Data Cleaning].dbo.NashvilleHousing
--------------------------------------------------------------------------------------------------------------------------

-- Standardize Sale Date Format
-- SaleDate data is in timedate format, but the time data is not used ('00:00:00.000')
--    SaleDate converted from timedate to date format
Select *
From [SQL Data Cleaning].dbo.NashvilleHousing

ALTER Table NashvilleHousing
ALTER COlUMN SaleDate Date;


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data that was left blank

Select *
From [SQL Data Cleaning].dbo.NashvilleHousing
--Where PropertyAddress is null
order by ParcelID

-- For rows with a null PropertyAddress, the address should be the same as any other row that has the same ParcelID
 
 -- Joining the table with itself in order to compare the values of ParcelID with different rows
 -- Joining where the ParcelID is the same, but the UniqueID is NOT the same
 -- ISNULL() expression will look for "a.PropertyAddress" values that are NULL, and replace it with "b.PropertyAddress"
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From [SQL Data Cleaning].dbo.NashvilleHousing a
JOIN [SQL Data Cleaning].dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From [SQL Data Cleaning].dbo.NashvilleHousing a
JOIN [SQL Data Cleaning].dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null
--After the above script is ran, the updated table should no longer have any NULL values in the PropertyAddress column



--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City)


Select PropertyAddress
From [SQL Data Cleaning].dbo.NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID

--Commas within PropertyAddress are only used as delimiters, so it can be used to separated the address from the city

--CHARIDEX searches for a specific value (a comma in this case)
--The "-1" removes the comma from the value of the Address (it moves the end position 1 place less to the left)
--The "+2" removes the comma and a space from the value of the city
--LEN() indicates where to end the SUBSTRING value, which will be the length of PropertyAddress
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2 , LEN(PropertyAddress)) as Address

From [SQL Data Cleaning].dbo.NashvilleHousing


--The values separated then need to be added to new columns to be stored within the table
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2 , LEN(PropertyAddress))




Select *
From [SQL Data Cleaning].dbo.NashvilleHousing




--OwnerAddress also has the city and state mixed in the Address value
--Instead of using SUBSTRING() it will be done using PARSENAME()
Select OwnerAddress
From [SQL Data Cleaning].dbo.NashvilleHousing

--PARSENAME looks for periods to split values, so REPLACE is used to change this existing commas to periods
-- 3,2,1 is used instead of 1,2,3 because PARSENAME takes the value from the right side of the period
-- So 1,2,3 would result in State, City, Address instead of Address, City, State
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From [SQL Data Cleaning].dbo.NashvilleHousing


-- Now using the above method below along with Alter Table to make the changes to the table
ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

Select *
From [SQL Data Cleaning].dbo.NashvilleHousing



--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "SoldAsVacant" field

-- Distinct() was used to see what values were currently being used in the "SoldAsVacant" column
-- The values are N, Yes, Y, and No
-- Count() was used to see how many of each value we have
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From [SQL Data Cleaning].dbo.NashvilleHousing
Group by SoldAsVacant
order by 2


--Using CASE to change "Y" to "Yes" and "N" to "No"
Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From [SQL Data Cleaning].dbo.NashvilleHousing

--Updating the table to apply the above changes
Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Removing duplicate data values

-- Partitioning by values that collectively should be unique for each row
WITH RowNumCTE AS(

Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
-- Where ever row_num is >1, there is a row of data that has the same values for the columns being partitioned
From [SQL Data Cleaning].dbo.NashvilleHousing

)
--DELETE
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress



Select *
From [SQL Data Cleaning].dbo.NashvilleHousing



-- Delete Unused Columns

ALTER TABLE [SQL Data Cleaning].dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

Select *
From [SQL Data Cleaning].dbo.NashvilleHousing
