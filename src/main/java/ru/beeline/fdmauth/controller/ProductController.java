/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.annotation.ApiErrorCodes;
import ru.beeline.fdmauth.domain.Product;
import ru.beeline.fdmauth.service.ProductService;
import ru.beeline.fdmauth.service.UserProfileService;

import java.util.List;

import static ru.beeline.fdmauth.utils.Constant.USER_ID_HEADER;

@RestController
@RequestMapping("/api")
@Tag(name = "Продукты", description = "Проверка и получение продуктов, привязанных к пользователям")
public class ProductController {

    @Autowired
    private ProductService productService;

    @Autowired
    private UserProfileService userProfileService;

    @ApiErrorCodes({400, 500})
    @GetMapping(value = "/product/{id}/existence", produces = "application/json")
    @Operation(summary = "Проверка существования продукта")
    public ResponseEntity<Boolean> checkProductExistence(@PathVariable Long id) {
        return ResponseEntity.ok(productService.checkProductExistenceById(id));
    }

    @ApiErrorCodes({400, 500})
    @GetMapping(value = "/user/{id}/product", produces = "application/json")
    @Operation(summary = "Получение списка продуктов пользователя по id",
            description = "Возвращает все продукты, привязанные к пользователю по его числовому идентификатору")
    public ResponseEntity<List<Product>> getProducts(@PathVariable Integer id) {
        return ResponseEntity.ok(productService.findProductsByUserId(id));
    }

    @ApiErrorCodes({400, 500})
    @GetMapping(value = "/admin/v1/product", produces = "application/json")
    @Operation(summary = "Получение продуктов текущего пользователя",
            description = "Возвращает продукты пользователя по заголовку X-User-Id. Требует авторизации")
    public ResponseEntity<List<Product>> getUserProducts(@RequestHeader(value = USER_ID_HEADER, required = false) String userId) {
        return ResponseEntity.ok(productService.findProductsByUserId(Integer.valueOf(userId)));
    }
}
