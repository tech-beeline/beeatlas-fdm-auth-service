package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.domain.Product;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.exception.EntityNotFoundException;
import ru.beeline.fdmauth.service.ProductService;
import ru.beeline.fdmauth.service.UserService;

import java.util.List;
import java.util.Optional;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api")
@Api(value = "Product API", tags = "Product")
public class ProductController {

    @Autowired
    private ProductService productService;

    @Autowired
    private UserService userService;


    @GetMapping(value = "/product/{id}/existence", produces = "application/json")
    @ApiOperation(value = "Проверка существования продукта", response = Boolean.class)
    public ResponseEntity<Boolean> checkProductExistence(@PathVariable Long id) {
        return ResponseEntity.ok(productService.checkProductExistenceById(id));
    }

    @GetMapping(value = "/user/{id}/product", produces = "application/json")
    @ApiOperation(value = "Получение списка продуктов пользователя", response = List.class)
    public ResponseEntity<List<Product>> getProducts(@PathVariable Long id) {
        Optional<UserProfile> userOpt = userService.findProfileById(id);
        if (!userOpt.isPresent()) {
            String errMessage = String.format("404 Пользователь c id '%s' не найден", id);
            throw new EntityNotFoundException(errMessage);
        } else {
            UserProfile user = userOpt.get();
            return ResponseEntity.ok(productService.findProductsByUser(user));
        }
    }
}