﻿USE OnlineOrderingSystem

-- NOTE: e t doi thoi gian hieu luc cua hop dongf sang kieu du lieu date, 
--       va so chi nhanh sang kieu du lieu small int vay thi phai sua file database lai
-- search may tu khoa DONE, ERROR: 
-- DONE la t kiem tra r 
-- ERROR la con thieu hoac t thac mac do 

GO 
-- STORE PROCEDURE FOR DOI_TAC
-- cap nhat thoi gian hieu luc va phan tram hoa hong  ==> DONE
GO 
CREATE PROCEDURE spUpdateContract @masothue varchar(20), @tg_hlhd date, @pthh float
AS
BEGIN TRAN
	IF IS_ROLEMEMBER('doi_tac') = 0 AND IS_ROLEMEMBER('db_owner') = 0
		BEGIN 
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END
	ELSE 
		BEGIN
			IF NOT EXISTS(SELECT h.MaDT FROM DOI_TAC d JOIN HOP_DONG h ON (d.MaDT = h.MaHD) WHERE d.MaSoThue = @masothue)
				BEGIN
					ROLLBACK TRAN
					PRINT('TRANSACTION IS ROLLBACKED')
				END 
			ELSE
				BEGIN
					DECLARE @madt varchar(20)
					DECLARE @doanhsoban float

					SET @madt = (SELECT h.MaDT FROM DOI_TAC d JOIN HOP_DONG h ON (d.MaDT = h.MaHD) WHERE d.MaSoThue = @masothue)
				
					-- Check if the input effective time is valid
					IF(@tg_hlhd < (SELECT h.TG_HieuLucHD FROM HOP_DONG h WHERE h.MaDT = @madt))
						BEGIN
							ROLLBACK TRAN
							PRINT('TRANSACTION IS ROLLBACKED')
						END
					ELSE
						BEGIN
							SET @doanhsoban = (SELECT SUM(d.TongPhiSP) FROM DON_HANG d WHERE d.MaDT = @madt)
				
							UPDATE HOP_DONG
							SET TG_HieuLucHD = @tg_hlhd, PhanTramHoaHong = (@pthh * @doanhsoban) / 100
							where MaDT = @madt

							COMMIT TRAN
						END
				END
		END


-- them thong tin san pham ==>DONE
GO
CREATE PROCEDURE spAddProduct @maSP varchar(20), @maCN varchar(20), @tensanpham nvarchar(50), @loai varchar(20), @gia float
AS
BEGIN TRAN 
	IF IS_ROLEMEMBER('doi_tac') = 0 OR IS_ROLEMEMBER('db_owner') = 0
		BEGIN
			IF EXISTS(SELECT * FROM SAN_PHAM WHERE MaSP = @maSP) OR NOT EXISTS (SELECT * FROM CHI_NHANH WHERE MaCN = @maCN) OR NOT EXISTS(SELECT * FROM LOAI_HANG WHERE MaLoai = @loai)
				BEGIN
					ROLLBACK TRAN
					PRINT('TRANSACTION IS ROLLBACKED')
				END 
			ELSE 
				BEGIN
					INSERT SAN_PHAM(MaSP, MaCN, TenSanPham, Loai, Gia)
					VALUES (@maSP, @maCN, @tensanpham, @loai, @gia)
					COMMIT TRAN
				END
		END
	ELSE
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END

-- sua thong tin san pham ==>DONE
GO
CREATE PROCEDURE spUpdateProduct @maSP varchar(20), @maCN varchar(20), @tensanpham nvarchar(50), @loai varchar(20), @gia float
AS
BEGIN TRAN 
	IF IS_ROLEMEMBER('doi_tac') = 0 OR IS_ROLEMEMBER('db_owner') = 0
		BEGIN
			IF NOT EXISTS(SELECT * FROM SAN_PHAM WHERE MaSP = @maSP) OR NOT EXISTS (SELECT * FROM CHI_NHANH WHERE MaCN = @maCN) OR NOT EXISTS(SELECT * FROM LOAI_HANG WHERE MaLoai = @loai) 
				BEGIN
					ROLLBACK TRAN
					PRINT('TRANSACTION IS ROLLBACKED')
				END 
			ELSE 
				BEGIN 
					UPDATE SAN_PHAM
					SET MaCN = @maCN, TenSanPham = @tensanpham, Loai = @loai, Gia = @gia
					where MaSP = @maSP
					COMMIT TRAN
				END
		END
	ELSE
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END


-- xoa thong tin san pham ==> DONE
GO
CREATE PROCEDURE spDeleteProduct @maSP varchar(20)
AS
BEGIN TRAN 
	IF IS_ROLEMEMBER('doi_tac') = 0 AND IS_ROLEMEMBER('db_owner') = 0
		BEGIN 
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END
	ELSE
		BEGIN
			IF NOT EXISTS(SELECT * FROM SAN_PHAM WHERE MaSP = @maSP)  
				BEGIN
					ROLLBACK TRAN
					PRINT('TRANSACTION IS ROLLBACKED')
				END 
			ELSE 
				BEGIN 
					DELETE FROM SAN_PHAM
					WHERE MaSP = @maSP
					COMMIT TRAN
				END
			
		END


-- ==> ERROR: Thao thieu them xoa sua chi nhanh cung cap san pham nay? ma neu cho nay mot san pham co the co 2 chi nhanh cung cap thi hoi vo ly ?

-- xem thong tin don hang ==>DONE
GO 
CREATE PROCEDURE spViewOrderInformation @madh varchar(20)
AS
BEGIN TRAN
	IF IS_ROLEMEMBER('doi_tac') = 0 AND IS_ROLEMEMBER('db_owner') = 0
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END
	ELSE
		BEGIN
		IF NOT EXISTS (SELECT * FROM DON_HANG WHERE MaDH = @madh)
			BEGIN
				ROLLBACK TRAN
				PRINT('TRANSACTION IS ROLLBACKED')
			END
		ELSE
			BEGIN
				SELECT * FROM DON_HANG WHERE MaDH = @madh
				COMMIT TRAN
			END
		END
GO 
USE OnlineOrderingSystem
GRANT EXEC ON spViewOrderInformation 
to doi_tac
-- cap nhat tinh trang don hang ==>DONE
GO 
CREATE PROCEDURE spUpdateOrderStatusForPartner @madt varchar(20),  @madh varchar(20), @ttdh nvarchar(50)
AS
BEGIN TRAN
	IF IS_ROLEMEMBER('doi_tac') = 0 AND IS_ROLEMEMBER('db_owner') = 0
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END
	ELSE
		BEGIN
			IF NOT EXISTS (SELECT * FROM DON_HANG WHERE MaDH = @madh and MaDT = @madt)
				BEGIN
					ROLLBACK TRAN
					PRINT('TRANSACTION IS ROLLBACKED')
				END
			ELSE
				IF (SELECT TinhTrangDH FROM DON_HANG WHERE MaDH = @madh) = 'Hoàn trả hàng'
					-- Not allow to update order status when the order is refunded
					BEGIN
						ROLLBACK TRAN
						PRINT('TRANSACTION IS ROLLBACKED')
					END
				ELSE IF ((SELECT TinhTrangDH FROM DON_HANG WHERE MaDH = @madh) = 'Đã giao hàng' AND @ttdh != 'Hoàn trả hàng')
					-- Not allow to update order status when the order is marked at delivered, except refund
					BEGIN
						ROLLBACK TRAN
						PRINT('TRANSACTION IS ROLLBACKED')
					END
				ELSE
					BEGIN
						UPDATE DON_HANG
						SET TinhTrangDH = @ttdh
						WHERE MaDH = @madh
						COMMIT TRAN
					END
		END


-- STORE PROCEDURE FOR KHACH HANG 
-- xem danh sach doi tac ==>DONE
GO 
CREATE PROCEDURE spViewPartnerList
AS
BEGIN TRAN
	IF IS_ROLEMEMBER('khach_hang') = 0 AND IS_ROLEMEMBER('db_owner') = 0
		BEGIN 
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END
	ELSE 
	BEGIN
		IF NOT EXISTS (SELECT * FROM DOI_TAC)
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END
		ELSE 
		BEGIN
			SELECT MaDT, TenDT, NguoiDaiDien, MaKV, MaLoai, DiaChiKD, SoDT, Email
			FROM DOI_TAC 
			COMMIT TRAN
		END 
		
	END

-- xem danh sach san pham cua doi tac ==>DONE
GO
CREATE PROCEDURE spViewProductListOfPartner @madt varchar(20)
AS
BEGIN TRAN 
	IF IS_ROLEMEMBER('khach_hang') = 0 AND IS_ROLEMEMBER('db_owner') = 0
	BEGIN
		ROLLBACK TRAN
		PRINT('TRANSACTION IS ROLLBACKED')
	END 
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT * FROM DOI_TAC WHERE MaDT = @madt)
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END
		ELSE 
		BEGIN
			SELECT sp.MaSP, sp.TenSanPham, sp.Gia, sp.Loai 
			FROM SAN_PHAM sp
			WHERE sp.MaCN in (SELECT cn.MACN FROM CHI_NHANH cn JOIN DOI_TAC dt ON cn.MADT = dt.MADT and dt.MaDT = @madt)
			COMMIT TRAN
		END 
	END

--==>ERROR: co that su can sp chon san pham so luong tuong ung ko??, cai nay tren UI ma t
GO
-- chon san pham, so luong tuong ung, hinh thuc thanh toan va dia chi giao hang
CREATE PROCEDURE spSelectOrderInformation @masp varchar(20), @soluong int, @ht_tt nvarchar(50), @tenduong nvarchar(50), @makv varchar(20)
AS
BEGIN TRAN 
	IF IS_ROLEMEMBER('khach_hang') = 0 AND IS_ROLEMEMBER('db_owner') = 0
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END 
	ELSE
		IF NOT EXISTS (SELECT * FROM SAN_PHAM WHERE MaSP = @masp)
			BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END
		ELSE
			BEGIN
				SELECT @masp AS MaSP, @soluong AS SoLuong, @ht_tt AS HinhThucThanhToan, @tenduong AS TenDuong, @makv AS MaKhuVuc
				FROM SAN_PHAM
				COMMIT TRAN
			END
--EXEC spSelectOrderInformation '000', 5, N'PayPal', N'Nguyễn Chí Thanh', '586'




-- xac nhan dong y, don hang se duoc chuyen den doi tac va tai xe (tao don hang) ==>DONE
GO
CREATE PROCEDURE spCreateOrder @madh varchar(20), @madt varchar(20), @makh varchar(20), @ht_tt nvarchar(50), @tenduong nvarchar(50), @makv varchar(20), @masp varchar(20), @soluong int
AS
BEGIN TRAN 
	IF IS_ROLEMEMBER('khach_hang') = 0 AND IS_ROLEMEMBER('db_owner') = 0
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END 
	ELSE
		BEGIN
			IF EXISTS (SELECT * FROM DON_HANG WHERE MaDH = @madh) 
				OR NOT EXISTS (SELECT * FROM DOI_TAC WHERE MaDT = @madt)
				OR NOT EXISTS (SELECT * FROM KHU_VUC WHERE MaKV = @makv)
				OR NOT EXISTS (SELECT * FROM SAN_PHAM WHERE MaSP = @masp)
				BEGIN
					ROLLBACK TRAN
					PRINT('TRANSACTION IS ROLLBACKED')
				END
			ELSE
				BEGIN
					INSERT DON_HANG
					VALUES (@madh, @madt, @makh, @ht_tt, @tenduong, @makv, 0, 0, null)
					INSERT CT_DONHANG
					VALUES (@madh, @masp, @soluong)
					UPDATE DON_HANG
					SET TongPhiSP = (SELECT SUM(ct.SoLuong*sp.Gia) FROM SAN_PHAM sp JOIN CT_DONHANG ct ON ct.MaDH = @madh and sp.MaSP = ct.MaSP group by ct.MaDH) where MaDH = @madh
					COMMIT TRAN
				END
			
		END
-- cap nhap don hang ==>DONE
GO
CREATE PROCEDURE spUpdateOrder @madh varchar(20), @madt varchar(20), @makh varchar(20), @ht_tt nvarchar(50), @tenduong nvarchar(50), @makv varchar(20), @masp varchar(20), @soluong int
AS
BEGIN TRAN 
	IF IS_ROLEMEMBER('khach_hang') = 0 AND IS_ROLEMEMBER('db_owner') = 0
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END 
	ELSE
		BEGIN
			IF NOT EXISTS (SELECT * FROM DON_HANG where MaDH = @madh)
				OR NOT EXISTS (SELECT * FROM DOI_TAC WHERE MaDT = @madt)
				OR NOT EXISTS (SELECT * FROM KHU_VUC WHERE MaKV = @makv)
				OR NOT EXISTS (SELECT * FROM SAN_PHAM WHERE MaSP = @masp)
				BEGIN
					ROLLBACK TRAN
					PRINT('TRANSACTION IS ROLLBACKED')
				END
			ELSE 
				BEGIN
					IF EXISTS (SELECT * FROM CT_DONHANG WHERE Madh = @madh AND MaSP = @masp)
						BEGIN
							UPDATE CT_DONHANG
							SET SoLuong = @soluong
							WHERE MaDH = @madh And MaSP = @masp
							UPDATE DON_HANG
							SET  HinhThuc_ThanhToan = @ht_tt, TenDuong = @tenduong, MaKV = @makv
							WHERE MaDH = @madh
							UPDATE DON_HANG
							SET TongPhiSP = (SELECT SUM(ct.SoLuong*sp.Gia) FROM SAN_PHAM sp JOIN CT_DONHANG ct ON ct.MaDH = @madh and sp.MaSP = ct.MaSP group by ct.MaDH) where MaDH = @madh
						END
					IF NOT EXISTS (SELECT * FROM CT_DONHANG WHERE Madh = @madh AND MaSP = @masp)
						BEGIN
							INSERT CT_DONHANG
							VALUES (@madh, @masp, @soluong)
							UPDATE DON_HANG
							SET TongPhiSP = (SELECT SUM(ct.SoLuong*sp.Gia) FROM SAN_PHAM sp JOIN CT_DONHANG ct ON ct.MaDH = @madh and sp.MaSP = ct.MaSP group by ct.MaDH) where MaDH = @madh
						END
					COMMIT TRAN
				END
		END

-- theo doi qua trinh van chuyen ==>DONE
GO
CREATE PROCEDURE spViewShippingProcess @madh varchar(20),@makh varchar(20)
AS
BEGIN TRAN 
	IF IS_ROLEMEMBER('khach_hang') = 0 AND IS_ROLEMEMBER('db_owner') = 0
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END 
	ELSE
		BEGIN
			IF NOT EXISTS (SELECT * FROM DON_HANG WHERE MaDH = @madh AND MaKH = @makh)
				BEGIN
					ROLLBACK TRAN
					PRINT('TRANSACTION IS ROLLBACKED')
				END
			ELSE 
				BEGIN
					SELECT TinhTrangDH
					FROM DON_HANG
					WHERE Madh = @madh 
					COMMIT TRAN	
				END 
		END

-- STORE PROCEDURE FOR TAI_XE
-- hien thi danh sach don hang theo khu vuc ==>DONE
GO 
CREATE PROCEDURE spViewOrderList @matx varchar(20)
AS
BEGIN TRAN
	IF IS_ROLEMEMBER('tai_xe') = 0 AND IS_ROLEMEMBER('db_owner') = 0
		BEGIN 
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END
	ELSE 
	BEGIN
		IF NOT EXISTS(SELECT MATX FROM TAI_XE WHERE  MaTX = @matx)
			BEGIN
				ROLLBACK TRAN
				PRINT('TRANSACTION IS ROLLBACKED')
			END 
		ELSE 
			BEGIN
				DECLARE @makv varchar(20);
				SET @makv = (SELECT MAKV FROM TAI_XE WHERE MaTX = @matx)
				SELECT DH.*
				FROM DON_HANG DH
				WHERE DH.MaKV = @makv AND DH.MaDH NOT IN (SELECT MADH FROM GIAO_HANG) 
				COMMIT TRAN
			END
	END

-- chon don hang phuc vu ==>DONE
--==>ERROR: cho hoi la vi du 1 don hang co the duoc 2 tai xe giao k ta?
GO
CREATE PROCEDURE spSelectOrder @maTX varchar(20), @madh varchar(20)
AS
BEGIN TRAN 
	IF IS_ROLEMEMBER('tai_xe') = 1 OR IS_ROLEMEMBER('db_owner') = 1
		BEGIN
			IF NOT EXISTS(SELECT * FROM TAI_XE WHERE MaTX = @maTX) 
			OR EXISTS (SELECT * FROM GIAO_HANG WHERE MaDH = @madh) 
			OR NOT EXISTS (SELECT * FROM DON_HANG WHERE MaDH = @madh) 
			OR NOT EXISTS (SELECT * FROM DON_HANG dh, TAI_XE tx WHERE dh.MaKV = tx.MaKV AND dh.MaDH = @madh AND tx.MaTX = @maTX)
				BEGIN
					ROLLBACK TRAN
					PRINT('TRANSACTION IS ROLLBACKED')
				END 
			ELSE 
				BEGIN 
					INSERT GIAO_HANG (MaTX,MaDH)
					VALUES (@maTX,@madh)
					COMMIT TRAN
				END

		END
	ELSE
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END


-- cap nhat tinh trang don hang 
GO 
CREATE PROCEDURE spUpdateOrderStatusForDriver @matx varchar(20), @madh varchar(20), @ttdh nvarchar(50)
AS
BEGIN TRAN
	IF IS_ROLEMEMBER('tai_xe') = 0 AND IS_ROLEMEMBER('db_owner') = 0
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END
	ELSE
		BEGIN
		IF NOT EXISTS (SELECT * FROM GIAO_HANG WHERE MaTX = @matx AND MaDH = @madh)
			BEGIN
				ROLLBACK TRAN
				PRINT('TRANSACTION IS ROLLBACKED')
			END
		ELSE
			BEGIN
				IF (SELECT TinhTrangDH FROM DON_HANG WHERE MaDH = @madh) = 'Hoàn trả hàng'
					-- Not allow to update order status when the order is refunded
					BEGIN
						ROLLBACK TRAN
						PRINT('TRANSACTION IS ROLLBACKED')
					END
				ELSE IF ((SELECT TinhTrangDH FROM DON_HANG WHERE MaDH = @madh) = 'Đã giao hàng' AND @ttdh != 'Hoàn trả hàng')
					-- Not allow to update order status when the order is marked at delivered, except refund
					BEGIN
						ROLLBACK TRAN
						PRINT('TRANSACTION IS ROLLBACKED')
					END
				ELSE
					BEGIN
						UPDATE DON_HANG
						SET TinhTrangDH = @ttdh
						WHERE MaDH = @madh
						COMMIT TRAN
					END
			END
		
		END

-- hien thi danh sach don hang ma tai xe da nhan  va phi van chuyen cua tung don hang ==>DONE
GO 
CREATE PROCEDURE spViewOrdersOfDriver @matx varchar(20)
AS
BEGIN TRAN
	IF IS_ROLEMEMBER('tai_xe') = 0 AND IS_ROLEMEMBER('db_owner') = 0
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END
	ELSE
		BEGIN
			IF NOT EXISTS(SELECT * FROM TAI_XE WHERE MaTX = @matx)
				BEGIN 
					ROLLBACK TRAN
					PRINT('TRANSACTION IS ROLLBACKED')
				END
			ELSE 
				BEGIN
					SELECT * FROM DON_HANG WHERE MADH IN (SELECT MADH FROM GIAO_HANG WHERE MaTX = @matx)
					COMMIT TRAN
				END
		END

-- STORE PROCEDURE FOR nhan vien 

-- xem danh sach hop dong da lap cua doi tac
GO
CREATE PROCEDURE spGetExpiredContract @madt varchar(20)
AS
BEGIN TRAN 
	IF IS_ROLEMEMBER('nhan_vien') = 0 
	AND IS_ROLEMEMBER('doi_tac') = 0
	AND IS_ROLEMEMBER('db_owner') = 0
	BEGIN
		ROLLBACK TRAN
		PRINT('TRANSACTION IS ROLLBACKED')
	END 
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT * FROM DOI_TAC WHERE MaDT = @madt)
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END
		ELSE 
		BEGIN
			SELECT hd.*
			FROM HOP_DONG hd
			WHERE hd.MaDT = @madt AND CAST( GETDATE() AS Date ) < hd.TG_HieuLucHD
			COMMIT TRAN
		END 
	END
-- xem danh sach hop dong da lap cua doi tac 
GO
CREATE PROCEDURE spGetAllConstractList @madt varchar(20)
AS
BEGIN TRAN 
	IF IS_ROLEMEMBER('nhan_vien') = 0 
	AND IS_ROLEMEMBER('doi_tac') = 0
	AND IS_ROLEMEMBER('db_owner') = 0
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END 
	ELSE
		BEGIN
			IF NOT EXISTS (SELECT * FROM DOI_TAC WHERE MaDT = @madt)
				BEGIN
					ROLLBACK TRAN
					PRINT('TRANSACTION IS ROLLBACKED')
				END
			ELSE 
				BEGIN
					SELECT hd.*
					FROM HOP_DONG hd
					WHERE hd.MaDT = @madt 
					COMMIT TRAN
				END 
		END
-- duyet hop dong ==>DONE
GO 
CREATE PROCEDURE spConfirmContract @mahd varchar(20),@madt varchar(20),@soCN smallint,@thoigianhieuluc date,@phantramhh float
AS
BEGIN TRAN
	IF IS_ROLEMEMBER('nhan_vien') = 0 
	AND IS_ROLEMEMBER('db_owner') = 0
	BEGIN
		ROLLBACK TRAN
		PRINT('TRANSACTION IS ROLLBACKED')
	END 
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT * FROM DOI_TAC WHERE MaDT = @madt)
			OR EXISTS (SELECT * FROM HOP_DONG WHERE MaHD = @mahd)
			OR @thoigianhieuluc <= CAST( GETDATE() AS Date )
			OR @phantramhh < 0
		BEGIN
			ROLLBACK TRAN
			PRINT('TRANSACTION IS ROLLBACKED')
		END
		ELSE 
		BEGIN
			INSERT INTO HOP_DONG
			VALUES (@mahd,@madt,@soCN,@thoigianhieuluc,@phantramhh)
			COMMIT TRAN
		END 
	END

-----------------STORED PROCEDURE FOR ADMIN--------------------

---- Create a user account for System Admin in master database
---- to execute server-level stored procedure
GO
USE master
CREATE USER user_sysadmin FOR LOGIN login_sysadmin
GRANT EXECUTE to user_sysadmin
GO
---------UPDATE INFORMATION OF LOGIN/USER ACCOUNT
-- Change login name
CREATE PROCEDURE sp_changeLoginName @oldName nvarchar(30), @newName nvarchar(30)
AS
	BEGIN TRAN CHANGELOGINNAME
		-- Check if current user is system admin
		DECLARE @currentUser AS NVARCHAR(100)
		SET @currentUser = (SELECT SYSTEM_USER)
		IF @currentUser != 'login_sysadmin'
			BEGIN
				PRINT('You do not have permission to do this. Transaction rollback...')
				ROLLBACK TRAN CHANGELOGINNAME
			END
		ELSE
			BEGIN
				-- Check invalid parameters
				IF LEN(@oldName) = 0 OR LEN(@newName) = 0
					BEGIN
						ROLLBACK TRAN CHANGELOGINNAME
						PRINT('Invalid parameter(s). Transaction rollback...')
					END
				-- Alter login name
				DECLARE @SQLQuery nvarchar(500)
				SET @SQLQuery = 'ALTER LOGIN ' + QUOTENAME(@oldName) + ' WITH NAME = ' + QUOTENAME(@newName)
				EXECUTE sp_executesql @SQLQuery
				COMMIT TRAN CHANGELOGINNAME
			END


-- Change login password
CREATE PROCEDURE sp_changeLoginPassword @loginName nvarchar(30), @newPassword nvarchar(30)
AS
	BEGIN TRAN CHANGELOGINPASSWORD
		-- Check if current user is system admin
		DECLARE @currentUser AS NVARCHAR(100)
		SET @currentUser = (SELECT SYSTEM_USER)
		IF @currentUser != 'login_sysadmin'
			BEGIN
				PRINT('You do not have permission to do this. Transaction rollback...')
				ROLLBACK TRAN CHANGELOGINPASSWORD
			END
		ELSE
			BEGIN
				-- Check invalid parameters
				IF LEN(@loginName) = 0 OR LEN(@newPassword) = 0
					BEGIN
						ROLLBACK TRAN CHANGELOGINPASSWORD
						PRINT('Invalid parameter(s). Transaction rollback...')
					END
				-- Alter login password
				DECLARE @SQLQuery nvarchar(500)
				SET @SQLQuery = 'ALTER LOGIN ' + QUOTENAME(@loginName) + ' WITH PASSWORD = ' + QUOTENAME(@newPassword)
				EXECUTE sp_executesql @SQLQuery
				COMMIT TRAN CHANGELOGINPASSWORD
			END



-- Change user name in database
USE OnlineOrderingSystem
GO
CREATE PROCEDURE sp_changeUsername @oldUsername nvarchar(30), @newUsername nvarchar(30)
AS
	BEGIN TRAN CHANGEUSERNAME
		-- Check if current user is system admin
		DECLARE @currentUser AS NVARCHAR(100)
		SET @currentUser = (SELECT SYSTEM_USER)
		IF @currentUser != 'login_sysadmin'
			BEGIN
				PRINT('You do not have permission to do this. Transaction rollback...')
				ROLLBACK TRAN CHANGEUSERNAME
			END
		ELSE
			BEGIN
				-- Check invalid parameters
				IF LEN(@oldUsername) = 0 OR LEN(@newUsername) = 0
					BEGIN
						ROLLBACK TRAN CHANGEUSERNAME
						PRINT('Invalid parameter(s). Transaction rollback...')
					END
				-- Alter user name
				DECLARE @SQLQuery nvarchar(500)
				SET @SQLQuery = 'ALTER USER ' + QUOTENAME(@oldUsername) + ' WITH NAME = ' + QUOTENAME(@newUsername)
				EXECUTE sp_executesql @SQLQuery
				COMMIT TRAN CHANGEUSERNAME
			END
GO

---------ADD/DELETE ACCOUNT OF ADMINS AND EMPLOYEES
-- Add login account for admin/employee
USE master
GO
CREATE PROCEDURE sp_addLoginAccount @loginName nvarchar(30), @loginPassword nvarchar(30)
AS
	BEGIN TRAN ADDLOGINACCOUNT
		-- Check if current user is system admin
		DECLARE @currentUser AS NVARCHAR(100)
		SET @currentUser = (SELECT SYSTEM_USER)
		IF @currentUser != 'login_sysadmin'
			BEGIN
				PRINT('You do not have permission to do this. Transaction rollback...')
				ROLLBACK TRAN ADDLOGINACCOUNT
			END
		ELSE
			BEGIN
				-- Check invalid parameters
				IF LEN(@loginName) = 0 OR LEN(@loginPassword) = 0
					BEGIN
						ROLLBACK TRAN ADDLOGINACCOUNT
						PRINT('Invalid parameter(s). Transaction rollback...')
					END
				-- Add login
				DECLARE @SQLQuery nvarchar(500)
				SET @SQLQuery = 'CREATE LOGIN ' + @loginName + ' WITH PASSWORD = ' + quotename(@loginPassword,'''')
				EXECUTE sp_executesql @SQLQuery
				COMMIT TRAN ADDLOGINACCOUNT
			END


-- Add user account for admin
CREATE PROCEDURE sp_addUserForAdmin @userName nvarchar(30), @loginName nvarchar(30)
AS
	BEGIN TRAN ADDUSERFORADMIN
		-- Check if current user is system admin
		DECLARE @currentUser AS NVARCHAR(100)
		SET @currentUser = (SELECT SYSTEM_USER)
		IF @currentUser != 'login_sysadmin'
			BEGIN
				PRINT('You do not have permission to do this. Transaction rollback...')
				ROLLBACK TRAN ADDLOGINFORADMIN
			END
		ELSE
			BEGIN
				-- Check invalid parameters
				IF LEN(@userName) = 0 OR LEN(@loginName) = 0
					BEGIN
						ROLLBACK TRAN ADDUSERFORADMIN
						PRINT('Invalid parameter(s). Transaction rollback...')
					END
				-- Add user for admin
				DECLARE @SQLQuery nvarchar(500)
				SET @SQLQuery = 'USE OnlineOrderingSystem CREATE USER ' + @userName + ' FOR LOGIN ' + @loginName
				EXECUTE sp_executesql @SQLQuery

				-- Add role for admin
				SET @SQLQuery = 'USE OnlineOrderingSystem ALTER ROLE db_owner ADD MEMBER ' + @userName
				EXECUTE sp_executesql @SQLQuery
				COMMIT TRAN ADDUSERFORADMIN
			END
GO

-- Add user account for employee
CREATE PROCEDURE sp_addUserForEmployee @userName nvarchar(30), @loginName nvarchar(30)
AS
	BEGIN TRAN ADDUSERFOREMPLOYEE
		-- Check if current user is system admin
		DECLARE @currentUser AS NVARCHAR(100)
		SET @currentUser = (SELECT SYSTEM_USER)
		IF @currentUser != 'login_sysadmin'
			BEGIN
				PRINT('You do not have permission to do this. Transaction rollback...')
				ROLLBACK TRAN ADDUSERFOREMPLOYEE
			END
		ELSE
			BEGIN
				-- Check invalid parameters
				IF LEN(@userName) = 0 OR LEN(@loginName) = 0
					BEGIN
						ROLLBACK TRAN ADDUSERFOREMPLOYEE
						PRINT('Invalid parameter(s). Transaction rollback...')
					END
				-- Add user for employee
				DECLARE @SQLQuery nvarchar(500)
				SET @SQLQuery = 'USE OnlineOrderingSystem CREATE USER ' + @userName + ' FOR LOGIN ' + @loginName
				EXECUTE sp_executesql @SQLQuery

				-- Add role for employee
				SET @SQLQuery = 'USE OnlineOrderingSystem ALTER ROLE nhan_vien ADD MEMBER ' + @userName
				EXECUTE sp_executesql @SQLQuery
				COMMIT TRAN ADDUSERFOREMPLOYEE
			END
GO

-- Delete user account of admin/employee
CREATE PROCEDURE sp_deleteUserAccount @userName nvarchar(30)
AS
	BEGIN TRAN DELETEUSERACCOUNT
		-- Check if current user is system admin
		DECLARE @currentUser AS NVARCHAR(100)
		SET @currentUser = (SELECT SYSTEM_USER)
		IF @currentUser != 'login_sysadmin'
			BEGIN
				PRINT('You do not have permission to do this. Transaction rollback...')
				ROLLBACK TRAN DELETEUSERACCOUNT
			END
		ELSE
			BEGIN
				-- Check invalid parameters
				IF LEN(@userName) = 0
					BEGIN
						ROLLBACK TRAN DELETEUSERACCOUNT
						PRINT('Invalid parameter(s). Transaction rollback...')
					END
				-- Delete user account
				DECLARE @SQLQuery nvarchar(500)
				SET @SQLQuery = 'DROP USER ' + @userName
				EXECUTE sp_executesql @SQLQuery
				COMMIT TRAN DELETEUSERACCOUNT
			END
GO

-- Lock login account of admin/employee
CREATE PROCEDURE sp_lockLoginAccount @loginName nvarchar(30)
AS
	BEGIN TRAN LOCKLOGINACCOUNT
		-- Check if current user is system admin
		DECLARE @currentUser AS NVARCHAR(100)
		SET @currentUser = (SELECT SYSTEM_USER)
		IF @currentUser != 'login_sysadmin'
			BEGIN
				PRINT('You do not have permission to do this. Transaction rollback...')
				ROLLBACK TRAN LOCKLOGINACCOUNT
			END
		ELSE
			BEGIN
				-- Check invalid parameters
				IF LEN(@loginName) = 0
					BEGIN
						ROLLBACK TRAN LOCKLOGINACCOUNT
						PRINT('Invalid parameter(s). Transaction rollback...')
					END
				-- Delete user account
				DECLARE @SQLQuery nvarchar(500)
				SET @SQLQuery = 'USE master ALTER LOGIN ' + QUOTENAME(@loginName) + ' DISABLE'
				EXECUTE sp_executesql @SQLQuery
				COMMIT TRAN LOCKLOGINACCOUNT
			END
GO

-- Unlock login account of admin/employee
CREATE PROCEDURE sp_unlockLoginAccount @loginName nvarchar(30)
AS
	BEGIN TRAN UNLOCKLOGINACCOUNT
		-- Check if current user is system admin
		DECLARE @currentUser AS NVARCHAR(100)
		SET @currentUser = (SELECT SYSTEM_USER)
		IF @currentUser != 'login_sysadmin'
			BEGIN
				PRINT('You do not have permission to do this. Transaction rollback...')
				ROLLBACK TRAN UNLOCKLOGINACCOUNT
			END
		ELSE
			BEGIN
				-- Check invalid parameters
				IF LEN(@loginName) = 0
					BEGIN
						ROLLBACK TRAN UNLOCKLOGINACCOUNT
						PRINT('Invalid parameter(s). Transaction rollback...')
					END
				-- Delete user account
				DECLARE @SQLQuery nvarchar(500)
				SET @SQLQuery = 'USE master ALTER LOGIN ' + QUOTENAME(@loginName) + ' ENABLE'
				EXECUTE sp_executesql @SQLQuery
				COMMIT TRAN UNLOCKLOGINACCOUNT
			END
GO

-- Lock user account of admin/employee
CREATE PROCEDURE sp_lockUserAccount @userName nvarchar(30)
AS
	BEGIN TRAN LOCKUSERACCOUNT
		-- Check if current user is system admin
		DECLARE @currentUser AS NVARCHAR(100)
		SET @currentUser = (SELECT SYSTEM_USER)
		IF @currentUser != 'login_sysadmin'
			BEGIN
				PRINT('You do not have permission to do this. Transaction rollback...')
				ROLLBACK TRAN LOCKUSERACCOUNT
			END
		ELSE
			BEGIN
				-- Check invalid parameters
				IF LEN(@userName) = 0
					BEGIN
						ROLLBACK TRAN LOCKUSERACCOUNT
						PRINT('Invalid parameter(s). Transaction rollback...')
					END
				-- Delete user account
				DECLARE @SQLQuery nvarchar(500)
				SET @SQLQuery = 'USE OnlineOrderingSystem DENY CONNECT ON DATABASE::OnlineOrderingSystem TO ' + @userName
				EXECUTE sp_executesql @SQLQuery
				COMMIT TRAN LOCKUSERACCOUNT
			END
GO

-- Unlock user account of admin/employee
CREATE PROCEDURE sp_unlockUserAccount @userName nvarchar(30)
AS
	BEGIN TRAN UNLOCKUSERACCOUNT
		-- Check if current user is system admin
		DECLARE @currentUser AS NVARCHAR(100)
		SET @currentUser = (SELECT SYSTEM_USER)
		IF @currentUser != 'login_sysadmin'
			BEGIN
				PRINT('You do not have permission to do this. Transaction rollback...')
				ROLLBACK TRAN UNLOCKUSERACCOUNT
			END
		ELSE
			BEGIN
				-- Check invalid parameters
				IF LEN(@userName) = 0
					BEGIN
						ROLLBACK TRAN UNLOCKUSERACCOUNT
						PRINT('Invalid parameter(s). Transaction rollback...')
					END
				-- Delete user account
				DECLARE @SQLQuery nvarchar(500)
				SET @SQLQuery = 'USE OnlineOrderingSystem GRANT CONNECT ON DATABASE::OnlineOrderingSystem TO ' + @userName
				EXECUTE sp_executesql @SQLQuery
				COMMIT TRAN UNLOCKUSERACCOUNT
			END
GO

SELECT * 
FROM master.INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE'
