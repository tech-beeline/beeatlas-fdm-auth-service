package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.domain.Product;
import ru.beeline.fdmauth.service.ProductService;

import java.util.List;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api")
@Api(value = "Product API", tags = "Product")
public class ProductController {

    @Autowired
    private ProductService productService;


    @GetMapping("/product/{id}/existence")
    @ApiOperation(value = "Проверка существования продукта", response = Boolean.class)
    public ResponseEntity<Boolean> checkProductExistence(@PathVariable Long id) {
        return ResponseEntity.ok(productService.checkProductExistenceById(id));
    }

    @GetMapping("/user/{id}/product")
    @ApiOperation(value = "Получение списка продуктов пользователя", response = List.class)
    public ResponseEntity<List<Product>> getProducts(@PathVariable Long id) {
        return ResponseEntity.ok(productService.findProductsByUserId(id));
    }

}